import { LightningElement, api, wire } from 'lwc';
import getDealSummary from '@salesforce/apex/DealSummaryController.getDealSummary';

export default class DealSummary extends LightningElement {

    
    // Opportunity Id from the record page context
    @api recordId; 
    
    // Data returned from Apex (DealSummaryDTO)
    data;

    // Captures any error returned by the wire service
    error;

    // --- Error Handling ---

    // Returns a user-friendly error message regardless of error shape
    get errorMessage() {
        if (!this.error) {
            return undefined;
        }

        // Safely handle different error shapes (Apex, JS, network)
        return this.error?.body?.message
            ? this.error.body.message      // Apex error format
            : this.error.message           // JS/Network error
            || JSON.stringify(this.error); // fallback
    }

    // --- UI State Mapping ---
    
    // Maps Quote Status → CSS class for visual indicators
    get quoteStatusClass() {
        // null-safe check to avoid runtime errors when quote does not exist
        if (!this.data || !this.data.quote || !this.data.quote.Status) {
            return '';
        }

        const status = this.data.quote.Status;

        // Map backend status → UI styling
        if (status === 'Approved') {
            return 'status-approved';
        }
        if (status === 'Rejected') {
            return 'status-rejected';
        }
        // Updated to handle "In Review" status specifically for Governance
        if (status === 'In Review') {
            return 'status-in-review';
        }

        // Default state for other statuse
        return 'status-draft';
    }

    // Computes average price per item (discounted total ÷ quantity)
    get productPrice() {
        // Prevent invalid calculation (nulls / division by zero)
        if (!this.data || !this.data.totalDiscounted || !this.data.totalQty || this.data.totalQty === 0) {
            return 0;
        }
        return this.data.totalDiscounted / this.data.totalQty;
    }

    // Checks if governance requires approval based on backend evaluation
    get isApprovalRequired() {
        return this.data?.readiness?.governance === 'APPROVAL_REQUIRED';
    }

    // --- Data Fetch (Wire Service) ---

    
    // Automatically calls Apex:
    // - On component load
    // - When recordId changes
    @wire(getDealSummary, { opportunityId: '$recordId' })
    wiredDealSummary({ error, data }) {
        if (data) {
            // Success: update state for rendering
            this.data = data;
            this.error = undefined;

        } else if (error) {
            // Failure: store error for display/debugging
            this.error = error;
            this.data = undefined;
        }
    }
}