import { LightningElement, api, wire } from 'lwc';
import getDealSummary from '@salesforce/apex/DealSummaryController.getDealSummary';

// Centralized readiness status constants to avoid hardcoded string
const STATUS = {
    READY: 'READY',
    NO_QUOTE: 'NO_QUOTE',
    QUOTE_NOT_ACCEPTED: 'QUOTE_NOT_ACCEPTED', 
    NO_PRODUCTS: 'NO_PRODUCTS',
    NO_PRIMARY_CONTACT: 'NO_PRIMARY_CONTACT',
    NO_EMAIL: 'NO_EMAIL',
    INVALID_PRICING: 'INVALID_PRICING',
    NOT_READY: 'NOT_READY'
};

export default class DealReadiness extends LightningElement {

    // Opportunity Id from record context
    @api recordId;

    // Holds readiness response from Apex
    readiness;

    // Fetch deal summary and extract readiness data
    @wire(getDealSummary, { opportunityId: '$recordId' })
    wireDealSummary({ error, data }) {
        if (data) {
            this.readiness = data.readiness;
        } else if (error) {
            // Log for debugging; UI handling can be added if needed
            console.error('Error fetching deal readiness:', error);
        }
    }

    // Updates progress bar width after render
    renderedCallback() {
        // Update progress bar width dynamically
        const progressBar = this.template.querySelector('.slds-progress-bar__value');
        if (progressBar) {
            progressBar.style.width = `${this.readinessProgress}%`;
        }
    }

    // Transforms readiness object into UI-friendly list
    get readinessList() {
        if (!this.readiness) return [];

        const items = [ 
            { 
                label: 'Quote', 
                status: this.readiness.quote, 
                iconName: this.getStatusIcon(this.readiness.quote),
                statusClass: this.getStatusClass(this.readiness.quote),
                ariaLabel: this.getAriaLabel({ label: 'Quote', status: this.readiness.quote }),
                description: this.getDescription(this.readiness.quote)
            },
            { 
                label: 'Products', 
                status: this.readiness.products, 
                iconName: this.getStatusIcon(this.readiness.products),
                statusClass: this.getStatusClass(this.readiness.products),
                ariaLabel: this.getAriaLabel({ label: 'Products', status: this.readiness.products }),
                description: this.getDescription(this.readiness.products)
            },
            { 
                label: 'Contacts', 
                status: this.readiness.contact, 
                iconName: this.getStatusIcon(this.readiness.contact),
                statusClass: this.getStatusClass(this.readiness.contact),
                ariaLabel: this.getAriaLabel({ label: 'Contacts', status: this.readiness.contact }),
                description: this.getDescription(this.readiness.contact)
            },
            { 
                label: 'Financials', 
                status: this.readiness.financials, 
                iconName: this.getStatusIcon(this.readiness.financials),
                statusClass: this.getStatusClass(this.readiness.financials),
                ariaLabel: this.getAriaLabel({ label: 'Financials', status: this.readiness.financials }),
                description: this.getDescription(this.readiness.financials)
            }
        ];

        // Enrich items with UI metadata (icon, styling, accessibility)
        items.forEach((item, index) => {
            item.showArrow = index < items.length - 1;
            item.arrowKey = item.label + '-arrow';
        });

        return items;
    }

    // Maps status → icon
    getStatusIcon(status) {
        switch (status) {
            case STATUS.READY:
                return 'utility:success';
            case STATUS.QUOTE_NOT_ACCEPTED:
            case STATUS.NO_EMAIL:
            case STATUS.INVALID_PRICING:
            case STATUS.NOT_READY:
                return 'utility:warning';
            case STATUS.NO_PRODUCTS:
            case STATUS.NO_PRIMARY_CONTACT:
            case STATUS.NO_QUOTE:
                return 'utility:error';
            default:
                return 'utility:info';
        }
    }

    // Maps status → SLDS color class
    getStatusClass(status) {
        switch (status) {
            case STATUS.READY:
                return 'slds-icon-text-success';
            case STATUS.NO_PRODUCTS:
            case STATUS.NO_PRIMARY_CONTACT:
            case STATUS.NO_QUOTE:
                return 'slds-icon-text-error';
            case STATUS.NO_EMAIL:
            case STATUS.INVALID_PRICING:
            case STATUS.QUOTE_NOT_ACCEPTED:
            case STATUS.NOT_READY:
                return 'slds-icon-text-warning';
            default:
                return '';
        }
    }

    // Computes percentage of completed readiness items
    get readinessProgress() {
        if (!this.readiness) return 0;

        let total = 4; 
        let readyCount = 0;

        if (this.readiness.quote === STATUS.READY) readyCount++;
        if (this.readiness.products === STATUS.READY) readyCount++;
        if (this.readiness.contact === STATUS.READY) readyCount++;
        if (this.readiness.financials === STATUS.READY) readyCount++;
        
        return Math.round((readyCount / total) * 100);
    }

    // Builds accessible label for screen readers
    getAriaLabel(item) {
        return `${item.label} status: ${item.status}`;
    }

    // Maps status → user-friendly description
    getDescription(status) {
        switch (status) {
            case STATUS.READY:
                return 'Ready';
            case STATUS.NO_QUOTE:
                return 'No quote associated';
            case STATUS.QUOTE_NOT_ACCEPTED:
                return 'Quote not accepted or ready for delivery';
            case STATUS.NO_PRODUCTS:
                return 'No products added';
            case STATUS.NO_PRIMARY_CONTACT:
                return 'No primary contact';
            case STATUS.NO_EMAIL:
                return 'Primary contact has no email';
            case STATUS.NOT_READY:
                return 'Financials not ready';
            default:
                return 'Unknown status';
        }
    }
}