public with sharing class QuoteLineItemValidationService {
    public static void enforceProductNotRepeated(List<QuoteLineItem> qlis) {
        Logger.info('QuoteLineItemValidation-enforceProductNotRepeated started');

        // Setting up for retrieval of Quotes from Database to to query QuoteLineItems AND Pricebook entries, we need to query the latter since Product2Id is not populated before insert
        Set<Id> qliQuoteIds = new Set<Id>();
        Set<Id> qliPbeIds = new Set<Id>();
        for (QuoteLineItem qli: qlis) {
            qliQuoteIds.add(qli.QuoteId);
            qliPbeIds.add(qli.PricebookEntryId);
        }

        // Setting up mappings from PriceBookEntryId to Product2Id since we need the Product2 as part of reqs
        Map<Id, Id> pbeToProduct2 = new Map<Id, Id>();
        // DONE: Make a model for this, SOQL isn't allowed here
        List<PriceBookEntry> pbes = PriceBookModel.getPriceBookEntry(new List<Id>(qliPbeIds));
        for (PriceBookEntry pbe: pbes) {
            pbeToProduct2.put(pbe.Id, pbe.Product2Id);
        }

        // Retrieval of QuoteLineItems from database using QuoteIds from Setup
        List<QuoteLineItem> existingQLIs = QuoteModel.getQuoteLineItems(new List<Id>(qliQuoteIds));
        Set<String> existingQuoteProductKeys = new Set<String>();
        Logger.debug('Got ' + existingQuoteProductKeys.size() + ' existing QuoteProductpair keys from database.');
        for (QuoteLineItem qli : existingQLIs) {
            if (qli.QuoteId == null || qli.Product2Id == null) {
                Logger.warn('A QuoteLineItem with a null QuoteId or Product2Id exists in the database, this offending record has not been taken into account on enforcing no products are repeated.');
                continue;
            }
            existingQuoteProductKeys.add(qli.QuoteId + '-' + qli.Product2Id);
            Logger.info('existing qpkey: ' + qli.QuoteId + '-' + qli.Product2Id);
        }

        // We add QuoteLineItems from the batch here if their QuoteProduct Key pair is unique (first seen)
        Map<String, QuoteLineItem> seenQLIs = new Map<String, QuoteLineItem>();
        // We add QuoteId-ProductId string pair here if an error has already been added, only applies to keys that are unique and thus have been added to the seenQLIs Map
        Set<String> qliHits = new Set<String>();

        for (QuoteLineItem qli : qlis) {
            String quoteProductKey = qli.QuoteId + '-' + pbeToProduct2.get(qli.PricebookEntryId);
            Logger.info('qpkey: ' + quoteProductKey);

            // Does the key exist in the database?
            if (existingQuoteProductKeys.contains(quoteProductKey)) {
                qli.addError('This QuoteLineItem cannot be added as another QuoteLineItem record with the same Product in the same Quote already exists.');
                Logger.warn('QuoteLineItem cannot be added as another QuoteLineItem record with the same Product in the same Quote already exists.');
            }
            // Does the key exist within the batch?
            else if (seenQLIs.containsKey(quoteProductKey)) {
                qli.addError('This QuoteLineItem cannot be added as another QuoteLineItem with the same Product in the same Quote is repeated in this batch.');
                Logger.warn('QuoteLineItem cannot be added as another QuoteLineItem with the same Product in the same Quote is repeated in this batch.');

                // Have we added an error to the first seen matching key yet?
                if (!qliHits.contains(quoteProductKey)) {
                    seenQLIs.get(quoteProductKey).addError('This QuoteLineItem cannot be added as another QuoteLineItem record with the same Product in the same Quote is repeated in this batch.');

                    qliHits.add(quoteProductKey);
                }
            // No matches? Then key is unique! add it to our watchlist for the next records
            } else {
                seenQLIs.put(quoteProductKey, qli);
            }
        }

        Logger.saveLog();
    }
}