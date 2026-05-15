import { LightningElement, api, wire } from 'lwc';
import getDealData from '@salesforce/apex/DealDashboard.getDealData';

export default class DealDashboard extends LightningElement {
    @api recordId;

    opportunity;
    quote;
    primaryContact;
    lineItems;
    error;

    @wire(getDealData, { oppId: '$recordId' })
    wiredDealData({ data, error }) {
        if (data) {
            this.opportunity = data.opp;
            this.quote = data.quote;
            this.primaryContact = data.primaryContact;
            this.lineItems = data.lineItems;
            this.error = undefined;

            console.log('DATA:', data);
        } else if (error) {
            this.error = error;
            this.opportunity = undefined;
            this.quote = undefined;
            this.primaryContact = undefined;
            this.lineItems = undefined;

            console.error('ERROR:', error);
        }
    }

    // Example computed fields
    get hasPrimaryContact() {
        return this.primaryContact != null;
    }

    get primaryContactHasEmail() {
        if (this.primaryContact != null) {
            return this.primaryContact.Contact.Email != null;
        }
        return false;
    }

    get hasQuote() {
        return this.quote != null;
    }

    get quoteHasProducts () {
        if (this.quote != null) {
            return this.quote.LineItemCount > 0;
        } 
        return false;
    }

    get quoteApproved () {
        if (this.quote != null) {
            return this.quote.Approval_Status__c == "Approved";
        } 
        return false;
    }

    get quoteAccepted () {
        if (this.quote != null) {
            return this.quote.Status == 'Accepted';
        } 
        return false;
    }

    get quoteInitialSent () {
        if (this.quote != null) {
            return this.quote.Initial_Quote_Sent__c;
        } 
        return false;
    }

}