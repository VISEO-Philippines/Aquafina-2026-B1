import { LightningElement, wire, track, api } from 'lwc';
import getQuoteRecord from '@salesforce/apex/OpportunitySyncedQuotesController.getQuoteRecord';

export default class QuoteStatusAlert extends LightningElement {
    @api recordId;
    @track discount;
    @track isDraft;
    @track isInReview;
    @track isApproved;
    @track isRejected;

    @wire(getQuoteRecord, {quoteId: '$recordId'})
    wiredQuoteRecord({error,data}){
        if(data){
            this.retrievedArray = JSON.stringify(data);
            if (this.retrievedArray === '[]'){
                return null;
            } 
            else if (data[0].Status == 'Draft' && data[0].Discount > 10.00) {
                // this.currentStatus = data[0].Status;
                // this.connectedCallback();
                this.isDraft = true;
                console.log('SUCCESS: ' + data[0].Status);
            } else if (data[0].Status == 'In Review' && data[0].Discount > 10.00){
                // this.currentStatus = data[0].Status;
                // this.connectedCallback();
                this.isInReview = true;
                console.log('SUCCESS: ' + data[0].Status);
            } else if (data[0].Status == 'Approved' && data[0].Discount > 10.00){
                // this.currentStatus = data[0].Status;
                // this.connectedCallback();
                this.isApproved = true;
                console.log('SUCCESS: ' + data[0].Status);
            } else if (data[0].Status == 'Rejected' && data[0].Discount > 10.00){
                // this.currentStatus = data[0].Status;
                // this.connectedCallback();
                this.isRejected = true;
                console.log('SUCCESS: ' + data[0].Status);
            } else {
                console.log('ERROR retrieving data. Retrieved Data: ' + JSON.stringify(data[0]));
                return null;
            }
        } else if (error){
            console.log('ERROR retrieving data. Status ' + JSON.stringify(error.Status) + ': '+JSON.stringify(error.body));
        }
    }
}