import { LightningElement, api, wire } from 'lwc';
import getQuote from '@salesforce/apex/QuoteModel.getQuote';

export default class ApprovalWarning extends LightningElement {
    @api recordId;

    quote;
    error;

    @wire(getQuote, { quoteId: '$recordId' })
    wiredQuote({ data, error }) {
        if (data) {
            console.log('DATA FROM APEX:', JSON.stringify(data));
            this.quote = data[0];
            this.error = undefined;
        } else if (error) {
            console.error('ERROR FROM APEX:', JSON.stringify(error));
            this.quote = undefined;
            this.error = error;
        }
    }

    connectedCallback() {
        console.log('recordID for APPROVAL WARNING: ', this.recordId);
    }   

    get isDraft() {
        if (this.quote) {
            return this.quote.Approval_Status__c === 'Draft' && this.quote.Discount > 10;

        } else {
            console.log('this.quote is empty.');
            return false;
        }
    }

    get isInReview() {
        if (this.quote) {
            return this.quote.Approval_Status__c === 'In Review' && this.quote.Discount > 10;

        }else {
            return false;
        }
    }

    get isApproved() {
        if (this.quote) {
            if (this.quote.Status === "Presented" || this.quote.Status === "Accepted") {
                return false;
            }
            return this.quote.Approval_Status__c === 'Approved' && this.quote.Discount > 10;

        }else {
            return false;
        }
    }

    get isRejected() {
        if (this.quote) {
            if (this.quote.Status === "Presented" || this.quote.Status === "Accepted") {
                return false;
            }
            return this.quote.Approval_Status__c === 'Rejected' && this.quote.Discount > 10;

        }else {
            return false;
        }
    }

    get isWithApproval() {
        return this.quote?.Discount > 10;
    }

    get isAutoApproved() {
        if (this.quote){
            if (this.quote.Status === "Presented" || this.quote.Status === "Accepted") {
                return false;
            }
        }

        console.log("Discount: ", this.quote?.Discount);
        console.log("Approval Stat: ", this.quote?.Approval_Status__c === 'Approved');
        return this.quote?.Discount <= 10 && this.quote?.Approval_Status__c === 'Approved';
    }
}