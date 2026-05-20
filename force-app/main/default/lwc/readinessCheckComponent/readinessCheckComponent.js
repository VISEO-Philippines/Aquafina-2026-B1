import checkForPrimary from '@salesforce/apex/OpportunityContactsController.checkForPrimary';
import checkForPrimaryEmail from '@salesforce/apex/OpportunityContactsController.checkForPrimaryEmail';
import checkForQuotes from '@salesforce/apex/OpportunitySyncedQuotesController.checkForQuotes';
import checkForQuoteStatus from '@salesforce/apex/OpportunitySyncedQuotesController.checkForQuoteStatus';
import checkForQuoteLineItems from '@salesforce/apex/QuoteLineItemsController.checkForQuoteLineItems';
import { api, LightningElement, wire } from 'lwc';

export default class ReadinessCheckComponent extends LightningElement {
    @api recordId; // gets ID of current record page; in this case, the opportunity ID

    hasPrimary;
    hasPrimaryEmail;
    hasQuote;
    hasQuoteLineItem;
    quoteIsApproved;
    totalsCalculated;

    @wire(checkForQuotes, {oppId: '$recordId'})
    getQuoteData({error,data}){
        if(data){
            // console.log('DUMAAN SA checkForQuotes');
            // console.log('QUOTE RETRIEVED: ' + JSON.stringify(data[0].IsSyncing));
            this.quoteRecord = JSON.stringify(data);
            if (JSON.stringify(data) == '[]'){
                return this.hasQuote = false;
            }
            else if (data[0].IsSyncing === true){
                // console.log('DUMAAN SA TAMANG DAANAN');
                return this.hasQuote = true;
            } else {
                return this.hasQuote = false;
            }

        } else if (error){
            this.quoteRecord = error;
            console.log('Error retrieving quote: ' + JSON.stringify(this.quoteRecord.body));
            return this.hasQuote = false;
        }
    }

    @wire(checkForQuoteStatus, {oppId: '$recordId'})
    getQuoteStatus({error,data}){
        if(data){
            //console.log('PHONEAS AND FERB: '+ JSON.stringify(data[0].Status));
            console.log('ITOOO234: ' + JSON.stringify(data));
            this.quoteRecord = data;

            if(this.quoteRecord == "[]"){
                return this.quoteIsApproved = false; 
            } else if (this.quoteRecord[0].Status != "Approved") {
                return this.quoteIsApproved = false;
            } else {
                return this.quoteIsApproved = true;
            }
            
        } else if (error){
            this.quoteRecord = error;
            console.log(JSON.stringify(this.quoteRecord));
            return this.quoteIsApproved = false;
        }
    }
    
    @wire(checkForQuoteLineItems, {oppId: '$recordId'})
    getQuoteLineItems({error,data}){
        if(data){
            console.log('ITO YUNNNNN: '+ JSON.stringify(data));
            this.quoteLineItemRecord = JSON.stringify(data);
            //console.log('ITO YUNNNNN: '+ this.quoteLineItemRecord);
            if(this.quoteLineItemRecord == "[]"){ //if sObject list empty
                return this.hasQuoteLineItem = false; 
            } else { 
                return this.hasQuoteLineItem = true;
            }
        } else if (error){
            this.quoteLineItemRecord = JSON.stringify(error);
            console.log('ITO YUNNNNN: '+ this.quoteLineItemRecord);
            console.log(JSON.stringify(error));
            return this.hasQuoteLineItem = false;
        }
    }

    @wire(checkForPrimaryEmail,{oppId: '$recordId'})
    getPrimaryOpportunityContactEmail({error, data}){
        if (data){
            this.hasPrimaryEmail = data; //data is boolean from apex side either true or false
            console.log('SUCCESS PRIMARY EMAIL');
        } else if (error){
            this.hasPrimaryEmail = 'Error retrieving primary contact email. ERROR '+ JSON.stringify(error.status) + ': ' + JSON.stringify(error.statusText);
            console.log('ERROR RETRIEVING PRIMARY EMAIL: ' + JSON.stringify(error));
            this.hasPrimaryEmail = false;
        }
    }

    @wire(checkForPrimary,{oppId: '$recordId'})
    getPrimaryContact({error, data}){
        if (data){
            this.hasPrimary = data; //data is boolean from apex side either true or false
            console.log('SUCCESS PRIMARY');
        } else if (error){
            this.hasPrimary = 'Error retrieving primary contact. ERROR '+ JSON.stringify(error.status) + ': ' + JSON.stringify(error.statusText);
            console.log('ERROR RETRIEVING PRIMARY: ' + JSON.stringify(error));
        }
    }

    @wire(checkForQuotes, {oppId: '$recordId'})
    getOpportunityTotalFromQuote({error,data}){
        if(data){
            // console.log('DUMAAN SA checkForQuotes');
            // console.log('QUOTE RETRIEVED: ' + JSON.stringify(data[0].IsSyncing));
            this.quoteRecord = JSON.stringify(data);
            if (JSON.stringify(data) == '[]'){
                return this.totalsCalculated = false;
            }
            else if (data[0].Opportunity.Total_Amount__c !== null){
                console.log('TOTALS detected!');
                return this.totalsCalculated = true;
            } else {
                return this.totalsCalculated = false;
            }

        } else if (error){
            this.quoteRecord = error;
            console.log('Error retrieving opportunity total: ' + JSON.stringify(this.quoteRecord.body));
            return this.totalsCalculated = false;
        }
    }
    
    // variable that always returns true
    // basically used to keep progress path visible always
    get pseudoVar(){
        return true;
    } 

    //using ternary method for a simpler solution to multiple else if statements
    get currentStep(){
        console.log('A' + JSON.stringify(this.hasQuote));
        console.log('B' + JSON.stringify(this.quoteIsApproved));
        console.log('C' + JSON.stringify(this.hasQuoteLineItem));
        console.log('D' + JSON.stringify(this.hasPrimary));
        console.log('E' + JSON.stringify(this.hasPrimaryEmail));
        console.log('F' + JSON.stringify(this.totalsCalculated));
        return String
        (
            !this.hasQuote ? 0: 
            !this.quoteIsApproved ? 1:
            !this.hasQuoteLineItem? 2:
            !this.hasPrimary ? 3:
            !this.hasPrimaryEmail ? 4:
            !this.totalsCalculated ? 5:
            6
        )
    }

    /* get currentStep(){
        // console.log('HAS QUOTE DITO AY:  ' + this.hasQuote);
        // console.log("UMABOT DITO");
        // Boolean variable; assign yung mga conditions something like Boolean hasQuoteAndIsApproved
        
        if (this.hasQuote == true && this.quoteIsApproved == true && this.hasQuoteLineItem == true && this.hasPrimary == true && this.hasPrimaryEmail == true && this.totalsCalculated == true){
            return "6";
        } else if (this.hasQuote == true && this.quoteIsApproved == true && this.hasQuoteLineItem == true && this.hasPrimary == true && this.hasPrimaryEmail == true){
            return "5";
        } else if (this.hasQuote == true && this.quoteIsApproved == true && this.hasQuoteLineItem == true && this.hasPrimary == true){
            return "4";
        } else if (this.hasQuote == true && this.quoteIsApproved == true && this.hasQuoteLineItem == true){
            return "3";
        } else if (this.hasQuote == true && this.quoteIsApproved == true){
            return "2";
        } else if (this.hasQuote == true){
            // console.log("Testing if it reaches here...");
            return "1";
        } else {
            // console.log("Maybe, here?");
            return "0";
        }

        // return String(this.hasQuote + this.quoteIsApproved + this.hasQuoteLineItem + this.hasPrimary + this.hasPrimaryEmail + this.totalsCalculated);

    } */
}