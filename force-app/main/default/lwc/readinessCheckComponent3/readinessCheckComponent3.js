import { LightningElement, api, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import checkForPrimary from '@salesforce/apex/OpportunityContactsController.checkForPrimary';
import checkForPrimaryEmail from '@salesforce/apex/OpportunityContactsController.checkForPrimaryEmail';
import checkForQuotes from '@salesforce/apex/OpportunitySyncedQuotesController.checkForQuotes';
import checkForQuoteStatus from '@salesforce/apex/OpportunitySyncedQuotesController.checkForQuoteStatus';
import checkForQuoteLineItems from '@salesforce/apex/QuoteLineItemsController.checkForQuoteLineItems';

export default class ReadinessCheckComponent3 extends LightningElement {
    @api recordId;

    hasPrimary;
    hasPrimaryEmail;
    hasQuote;
    hasQuoteLineItem;
    quoteIsApproved;
    cStep;

    @wire(checkForQuotes, {oppId: '$recordId'})
    wireData3({error,data}){
        if(data){
            // console.log('DUMAAN SA checkForQuotes');
            // console.log('QUOTE RETRIEVED: ' + JSON.stringify(data[0].IsSyncing));
            this.quoteRecord = JSON.stringify(data);
            if (JSON.stringify(data) == '[]'){
                return this.hasQuote = false;
            }
            else if (data[0].IsSyncing === true){
                console.log('DUMAAN SA TAMANG DAANAN');
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
    wireData5({error,data}){
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
    wireData4({error,data}){
        if(data){
            console.log('ITO YUNNNNN: '+ JSON.stringify(data));
            this.quoteLineItemRecord = JSON.stringify(data);
            //console.log('ITO YUNNNNN: '+ this.quoteLineItemRecord);
            if(this.quoteLineItemRecord == "[]"){ //if sObject list empty
                return this.hasQuoteLineItem = false; 
            } else { 
                return this.hasQuoteLineItem = true;
            }
            console.log(JSON.stringify(this.quoteLineItemRecord));
        } else if (error){
            this.quoteLineItemRecord = JSON.stringify(error);
            console.log('ITO YUNNNNN: '+ this.quoteLineItemRecord);
            console.log(JSON.stringify(error));
            return this.hasQuoteLineItem = false;
        }
    }

    @wire(checkForPrimaryEmail,{oppId2: '$recordId'})
    wiredData({error, data}){
        if (data){
            this.hasPrimaryEmail = data; //data is boolean from apex side either true or false
            console.log('SUCCESS PRIMARY EMAIL');
        } else if (error){
            this.hasPrimaryEmail = 'Error retrieving primary contact email. ERROR '+ JSON.stringify(error.status) + ': ' + JSON.stringify(error.statusText);
            console.log('ERROR RETRIEVING PRIMARY EMAIL: ' + JSON.stringify(error));
        }
    }

    @wire(checkForPrimary,{oppId3: '$recordId'})
    wiredData2({error, data}){
        if (data){
            this.hasPrimary = data; //data is boolean from apex side either true or false
            console.log('SUCCESS PRIMARY');
        } else if (error){
            this.hasPrimary = 'Error retrieving primary contact. ERROR '+ JSON.stringify(error.status) + ': ' + JSON.stringify(error.statusText);
            console.log('ERROR RETRIEVING PRIMARY: ' + JSON.stringify(error));
        }
    }

    get pseudoVar(){
        return true;
    } 

    get currentStep(){
        console.log('HAS QUOTE DITO AY:  ' + this.hasQuote);
        console.log("UMABOT DITO");
        if (this.hasQuote == true && this.quoteIsApproved == true && this.hasQuoteLineItem == true && this.hasPrimary == true && this.hasPrimaryEmail == true){
            return "6";
        } else if (this.hasQuote == true && this.quoteIsApproved == true && this.hasQuoteLineItem == true && this.hasPrimary == true){
            return "5";
        } else if (this.hasQuote == true && this.quoteIsApproved == true && this.hasQuoteLineItem == true){
            return "4";
        } else if (this.hasQuote == true && this.quoteIsApproved == true){
            return "3";
        } else if (this.hasQuote == true){
            console.log("WHAT ABT HERE");
            return "2";
        } else {
            console.log("NEIN, HERE");
            return "1";
        }

        console.log('dito rin' + JSON.Sthis.cStep);
    }
    
    
}