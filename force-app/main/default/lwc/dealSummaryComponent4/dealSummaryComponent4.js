import { LightningElement, wire, api} from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import getQuoteLineItems from "@salesforce/apex/FetchQuoteLineItems.fetchQuoteLineItemWrapperClass";
import checkIfHasLineItems from "@salesforce/apex/FetchQuoteLineItems.checkIfHasLineItems";

const URL_ORG = 'https://orgfarm-551bd49b6a-dev-ed.develop.lightning.force.com/lightning/r/';
const URL_ALL_ACCOUNTS = 'https://orgfarm-551bd49b6a-dev-ed.develop.lightning.force.com/lightning/o/Account/list?filterName=AllAccounts';
const URL_ALL_QUOTES = '';
const URL_ALL_PRICING_BOOKS = '';

//Field Instances  (Not String objects)
//CUSTOMER / DEAL CONTEXT
import ACCOUNT_ID_FIELD from "@salesforce/schema/Opportunity.AccountId";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Opportunity.Account.Name";
import ACCOUNT_CUSTOMER_TYPE_FIELD from "@salesforce/schema/Opportunity.Account.Customer_Type__c";
import OPPORTUNITY_TYPE_FIELD from "@salesforce/schema/Opportunity.Type";

import OPPORTUNITY_NAME_FIELD from "@salesforce/schema/Opportunity.Name";
import OPPORTUNITY_STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import OPPORTUNITY_CLOSE_DATE_FIELD from "@salesforce/schema/Opportunity.CloseDate";

import OPPORTUNITY_EFFECTIVE_DEAL_DISCOUNT_FIELD from "@salesforce/schema/Opportunity.Effective_Deal_Discount__c";

// QUOTE
import SYNCED_QUOTE_ID_FIELD from "@salesforce/schema/Opportunity.SyncedQuoteId";
import SYNCED_QUOTE_NAME_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.Name";
import QUOTE_NUMBER_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.QuoteNumber";
import LINE_ITEM_COUNT_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.LineItemCount";
import EXPIRATION_DATE_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.ExpirationDate";
import IS_SYNCED_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.IsSyncing";
import QUOTE_STATUS_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.Status";

// PRICING
import DISCOUNT_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.Discount";
import SUBTOTAL_FIELD from "@salesforce/schema/Opportunity.SyncedQuote.Subtotal";
import AMOUNT_FIELD from "@salesforce/schema/Opportunity.Amount";
import VAT_FIELD from "@salesforce/schema/Opportunity.VAT_Amount__c";

//QUOTE LINE ITEMS COLUMNS
const columns = [
    {
        label: 'Product',
        fieldName: 'quoteLineItemLink',
        type:'url',
        typeAttributes: {
            label: {
                fieldName: 'quoteLineItemName'
            },
            target: '_blank',
        }
    },
    {
        label: 'Quantity',
        fieldName: 'quantity',
    },
    {
        label: 'Discount (%)',
        fieldName: 'discount',
    },
    {
        label: 'Subtotal (€)',
        fieldName: 'subtotal',
    },
    {
        label: 'Total Discounted (€)',
        fieldName: 'totalDiscounted',
    },
]


// connected callback
// rendered -> trick css

export default class DealSummaryComponent4 extends LightningElement {
    //QUOTE LINE ITEMS
    columns = columns;
    data;
    error;

    @wire (getQuoteLineItems, {oppId: '$recordId'})
    wiredQuoteLineItemData({error, data}){
        if(data){
            this.data = data;
        } 
        else {
            this.error = error;
        }
    }
    
    // context awareness to retrieve records only those to open page
    @api recordId;

    // fields to query from opportunity record page
    fields = [ACCOUNT_ID_FIELD, ACCOUNT_NAME_FIELD, ACCOUNT_CUSTOMER_TYPE_FIELD, OPPORTUNITY_TYPE_FIELD, OPPORTUNITY_NAME_FIELD, OPPORTUNITY_STAGE_FIELD, OPPORTUNITY_CLOSE_DATE_FIELD, OPPORTUNITY_EFFECTIVE_DEAL_DISCOUNT_FIELD, SYNCED_QUOTE_ID_FIELD, SYNCED_QUOTE_NAME_FIELD, QUOTE_NUMBER_FIELD, LINE_ITEM_COUNT_FIELD, EXPIRATION_DATE_FIELD, IS_SYNCED_FIELD, QUOTE_STATUS_FIELD, DISCOUNT_FIELD, SUBTOTAL_FIELD, AMOUNT_FIELD, VAT_FIELD];


    @wire(getRecord, {recordId: '$recordId', fields: '$fields'}) opportunity;
    
    //CUSTOMER/ DEAL CONTEXT    
    get accountName(){
        return getFieldValue(this.opportunity.data, ACCOUNT_NAME_FIELD);
    }

    get customerType(){
        return getFieldValue(this.opportunity.data, ACCOUNT_CUSTOMER_TYPE_FIELD);
    }

    get opportunityType(){
        return getFieldValue(this.opportunity.data, OPPORTUNITY_TYPE_FIELD);
    }

    get opportunityName(){
        return getFieldValue(this.opportunity.data, OPPORTUNITY_NAME_FIELD);
    } 

    get opportunityStage(){
        return getFieldValue(this.opportunity.data, OPPORTUNITY_STAGE_FIELD);
    }

    get opportunityCloseDate(){
        return getFieldValue(this.opportunity.data, OPPORTUNITY_CLOSE_DATE_FIELD);
    }

    get effectiveDealDiscount(){
        return getFieldValue(this.opportunity.data, OPPORTUNITY_EFFECTIVE_DEAL_DISCOUNT_FIELD);
    }

    //QUOTES AND PRODUCT OVERVIEW
    get quoteName(){
        return getFieldValue(this.opportunity.data, SYNCED_QUOTE_NAME_FIELD);
    }

    get quoteNumber(){
        return getFieldValue(this.opportunity.data, QUOTE_NUMBER_FIELD);
    }

    get lineItemNumber(){
        return getFieldValue(this.opportunity.data, LINE_ITEM_COUNT_FIELD);
    }

    get ExpirationDate(){
        return getFieldValue(this.opportunity.data, EXPIRATION_DATE_FIELD);
    }

    get isSynced(){
        return getFieldValue(this.opportunity.data, IS_SYNCED_FIELD);
    }

    get quoteStatus(){
        return getFieldValue(this.opportunity.data, QUOTE_STATUS_FIELD);
    }

    //PRICING
    // Number -> Currency formatting docs: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat
    get subtotal(){
        this.subtotalInt = getFieldValue(this.opportunity.data, SUBTOTAL_FIELD);
        return Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.subtotalInt,);
    }

    get discount(){
        return getFieldValue(this.opportunity.data, DISCOUNT_FIELD);
    }

    get netAmount(){
        this.netAmountInt = getFieldValue(this.opportunity.data, AMOUNT_FIELD);
        return Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.netAmountInt,);
    }

    get vat(){
        this.vatInt = getFieldValue(this.opportunity.data, VAT_FIELD);
        return Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.vatInt,);
    }

    get totalDiscountedAmount(){
        this.totalDiscountedAmountInt = this.subtotalInt * (this.discount/100);
        return Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.totalDiscountedAmountInt,);
    }

    get totalAmount(){
        this.totalAmountInt = this.netAmountInt + this.vatInt;
        return Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(this.totalAmountInt,);
    }

    
    //IDs of associated objects
    get accountId(){
        return getFieldValue(this.opportunity.data, ACCOUNT_ID_FIELD);
    }

    get quoteId(){
        return getFieldValue(this.opportunity.data, SYNCED_QUOTE_ID_FIELD);
    }

    get hasQli(){
        //this.quoteIdValue = getFieldValue(this.opportunity.data, SYNCED_QUOTE_ID_FIELD);
        if (this.quoteId !== null){
            return true
        } else {
            return false;
        } 
     }

    //URLs to navigate to associated objects
    get accountUrl(){
        const URL_OBJECT = 'Account/';
        const URL_PERMISSION = '/view';
        return (URL_ORG + URL_OBJECT + String(this.accountId) + URL_PERMISSION);
    }

    get quoteUrl(){
        const URL_OBJECT = 'Quote/';
        const URL_PERMISSION = '/view';
        return (URL_ORG + URL_OBJECT + String(this.quoteId) + URL_PERMISSION);
    }

    get quoteLineItemsUrl(){
        const URL_OBJECT = 'Quote/';
        const URL_RELATED_OBJECT = '/related/QuoteLineItems';
        const URL_PERMISSION = '/view';
        return (URL_ORG + URL_OBJECT + String(this.quoteId) + URL_RELATED_OBJECT + URL_PERMISSION);
    }
}