import { LightningElement, api, wire } from 'lwc';
import fetchPrimaryOppContactRoles from '@salesforce/apex/ReadinessCheckController.fetchPrimaryOppContactRoles';
import fetchQuotes from '@salesforce/apex/ReadinessCheckController.fetchQuotes';

export default class RevisedReadinessCheckComponent extends LightningElement {
    @api recordId;

    // Boolean variables
    hasPrimary;
    hasPrimaryEmail;
    hasQuote;
    hasQuoteLineItem;
    quoteIsApproved;
    totalsCalculated;

    //list variables
    quoteRecord;
    OppContRoleRecord;


    @wire(fetchQuotes, {opportunityId: '$recordId'})
    getQuoteRecord({error,data}){
        if(data)
        {
            this.quoteRecord = data;

            this.hasQuote = this.quoteRecord.length > 0 && this.quoteRecord[0].IsSyncing === true;
            this.quoteIsApproved = this.quoteRecord[0].Status === 'Approved';
            this.hasQuoteLineItem = this.quoteRecord[0].LineItemCount > 0;
            this.totalsCalculated = this.quoteRecord[0].Subtotal !== null && this.quoteRecord[0].Subtotal > 0;

        } 
        
        else if (error)
        {
            this.hasQuote = false;
            this.printMe = JSON.stringify(error.body);
        }
    }

    @wire(fetchPrimaryOppContactRoles, {opportunityId: '$recordId'})
    getPrimaryContactRoleRecord({error,data}){
        if(data)
        {
            this.OppContRoleRecord = data;

            // primary contact role validation
            this.hasPrimary = this.OppContRoleRecord.length > 0;
            this.hasPrimaryEmail = this.OppContRoleRecord[0].Contact.Email !== null;

        } 
        else if (error)
        {
            console.log("boiiiiiii");
            this.hasPrimary = JSON.stringify(error.body);
        }
    }

    //using ternary method for a simpler solution to multiple else if statements
    get currentStep2(){
        return String
        (
            !this.hasQuote ? 0: 
            !this.quoteIsApproved ? 1:
            !this.hasQuoteLineItem ? 2:
            !this.hasPrimary ? 3:
            !this.hasPrimaryEmail ? 4:
            !this.totalsCalculated ? 5:
            6
        )
    }

    // just to get path to be visible at all times
    get pseudoVar(){
        return true;
    } 
}