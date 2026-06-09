import { LightningElement, api, wire, track } from 'lwc';
import getDealSummary from '@salesforce/apex/DealSummaryController.getDealSummary';

export default class DealSummaryCard extends LightningElement {
    @api recordId;
    // Summary payload returned by Apex for the active Opportunity record.
    @track summary = {};
    isLoading = true;
    error;

    // Reactive wire call re-runs whenever recordId changes.
    @wire(getDealSummary, { opportunityId: '$recordId' })
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.isLoading = false;
        }
    }

    get hasError() {
        return !!this.error;
    }

    // Present discount as a user-friendly percent; fallback to em dash if missing.
    get effectiveDiscountFormatted() {
        return this.summary.effectiveDiscount
            ? (this.summary.effectiveDiscount).toFixed(2) + '%'
            : '—';
    }

    // Quote status label displayed in the hero and in Financial Overview.
    get quoteStatusLabel() {
        return this.summary.quoteStatus || 'No quote';
    }

    // Map quote status to semantic pill styles.
    get statusPillClass() {
        const status = this.summary.quoteStatus;
        const classes = {
            Approved: 'status-pill status-pill_success',
            Draft: 'status-pill status-pill_warning',
            'In Review': 'status-pill status-pill_info',
            Rejected: 'status-pill status-pill_error'
        };

        return classes[status] || 'status-pill status-pill_neutral';
    }

    // Show how many readiness checks are currently passing.
    get readinessSummary() {
        const checks = this.readinessChecks;
        const passed = checks.filter((check) => check.variant === 'success').length;
        return `${passed} of ${checks.length} checks passed`;
    }

    // AUTO-COMPUTED — user cannot change these
    get readinessChecks() {
        const s = this.summary;
        return [
            {
                label: 'Quote exists',
                icon: s.hasQuote ? 'utility:success' : 'utility:error',
                variant: s.hasQuote ? 'success' : 'error',
                rowClass: s.hasQuote ? 'check-item check-item_success' : 'check-item check-item_error'
            },
            {
                label: 'Is Approved',
                icon: s.quoteAccepted ? 'utility:success' : 'utility:warning',
                variant: s.quoteAccepted ? 'success' : 'warning',
                rowClass: s.quoteAccepted ? 'check-item check-item_success' : 'check-item check-item_warning'
            },
            {
                label: 'Quote has Products',
                icon: s.quoteHasProducts ? 'utility:success' : 'utility:error',
                variant: s.quoteHasProducts ? 'success' : 'error',
                rowClass: s.quoteHasProducts ? 'check-item check-item_success' : 'check-item check-item_error'
            },
            {
                label: 'Primary Contact exists',
                icon: s.hasPrimaryContact ? 'utility:success' : 'utility:error',
                variant: s.hasPrimaryContact ? 'success' : 'error',
                rowClass: s.hasPrimaryContact ? 'check-item check-item_success' : 'check-item check-item_error'
            },
            {
                label: 'Primary Contact has Email',
                icon: s.contactHasEmail ? 'utility:success' : 'utility:warning',
                variant: s.contactHasEmail ? 'success' : 'warning',
                rowClass: s.contactHasEmail ? 'check-item check-item_success' : 'check-item check-item_warning'
            },
            {
                label: 'Financial totals can be calculated',
                icon: s.financialsCalculable ? 'utility:success' : 'utility:error',
                variant: s.financialsCalculable ? 'success' : 'error',
                rowClass: s.financialsCalculable ? 'check-item check-item_success' : 'check-item check-item_error'
            }
        ];
    }
}