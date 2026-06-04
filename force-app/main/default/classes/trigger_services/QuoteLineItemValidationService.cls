public with sharing class QuoteLineItemValidationService {
    private static final String DUPLICATE_DATABASE_ERROR = 'This QuoteLineItem cannot be added because another QuoteLineItem with the same Product already exists in this Quote.';
    private static final String DUPLICATE_BATCH_ERROR = 'QuoteLineItem cannot be added as another QuoteLineItem with the same Product in the same Quote is repeated in this batch.';


    public static void enforceProductNotRepeated(List<QuoteLineItem> qlis, List<QuoteLineItem> oldqlis) {
        Logger.info('QuoteLineItemValidation-enforceProductNotRepeated started');

        Set<Id> qliQuoteIds = new Set<Id>();
        Set<Id> qliPbeIds = new Set<Id>();

        retrieveIdsFromTrigger(qlis, qliQuoteIds, qliPbeIds);
        Map<Id, Id> pbeToProduct2 = getPbeToProduct2Mapping(qliPbeIds);
        Set<String> existingQuoteProductKeys = retrieveQuoteProductKeysFromDatabase(qliQuoteIds, qlis, oldqlis);
        validateDuplicateProducts(qlis, pbeToProduct2, existingQuoteProductKeys);
        Logger.debug('Got ' + existingQuoteProductKeys.size() + ' existing QuoteProductpair keys from database.');

        Logger.saveLog();
    }
    
    private static void retrieveIdsFromTrigger(List<QuoteLineItem> qlis, Set<Id> qliQuoteIds, Set<Id> qliPbeIds) {
        // Setting up for retrieval of Quotes from Database to to query QuoteLineItems AND Pricebook entries, we need to query the latter since Product2Id is not populated before insert
        for (QuoteLineItem qli: qlis) {
            qliQuoteIds.add(qli.QuoteId);
            qliPbeIds.add(qli.PricebookEntryId);
        }
    }

    private static Map<Id, Id> getPbeToProduct2Mapping(Set<Id> qliPbeIds) {
        // Setting up mappings from PriceBookEntryId to Product2Id since we need the Product2 as part of reqs
        Map<Id, Id> pbeToProduct2 = new Map<Id, Id>();
        List<PriceBookEntry> pbes = PriceBookModel.getPriceBookEntry(new List<Id>(qliPbeIds));
        for (PriceBookEntry pbe: pbes) {
            pbeToProduct2.put(pbe.Id, pbe.Product2Id);
        }
        return pbeToProduct2;
    }

    private static Set<String> retrieveQuoteProductKeysFromDatabase(Set<Id> qliQuoteIds, List<QuoteLineItem> qlis, List<QuoteLineItem> oldqlis) {
        // Retrieval of QuoteLineItems from database using QuoteIds from Setup
        Set<String> existingQuoteProductKeys = new Set<String>();

        List<QuoteLineItem> existingQLIs = QuoteModel.getQuoteLineItems(new List<Id>(qliQuoteIds));
        Logger.debug('QUOTE IDS WATCHED: ' + qliQuoteIds);
        Logger.debug('EXISTING QLIs RETRIEVED: ' + existingQLIs);

        // Get all the IDs of the incoming QLIs, incoming insert records will have null, while existing records have populated ids that are updates
        // if it is an update then we will ignore that in comparison since that data is already rendered stale by the incoming insert.
        List<Id> oldQLIIds = new List<Id>(new Map<Id, SObject>(oldqlis).keySet());
        Set<Id> triggeredQLIIds = new Set<Id>();
        for (QuoteLineItem qli: qlis) {
            // This means this is NOT an insert, will replace this with Trigger.old
            if (qli.Id != null) {
                // further enforces that this is an update, we are checking Trigger.new if both Trigger.new and Trigger.old contains the same Id then it is an update. possible problem here is that Trigger.new is also populated during undeletes and we still dont know if they will be included here but they might not be relevant since deleted objects are not queried during normal SOQL queries.
                // TL;DR this additional requirement for 'ignoring' database entries is redundant, it should work even if we remove the if statement below.
                if (oldQLIIds.contains(qli.Id))
                    triggeredQLIIds.add(qli.Id);
            }
        }

        for (QuoteLineItem qli : existingQLIs) {
            if (qli.QuoteId == null || qli.Product2Id == null) {
                // This should not be happening in normal transactions so logging this even if inside the loop should be ok?
                Logger.warn('A QuoteLineItem with a null QuoteId or Product2Id exists in the database, this offending record has not been taken into account on enforcing no products are repeated. Offending QuoteLineItem Id: ' + qli.Id);
                continue;
            } else if (triggeredQLIIds.contains(qli.Id)) {
                // Logger.warn('EXEMPTED A QLI SINCE IT IS AN UPDATE: ' + qli.Id + ' ' + qli.QuoteId + '-' + qli.Product2Id);
                continue;
            } else {
                existingQuoteProductKeys.add(qli.QuoteId + '-' + qli.Product2Id);
            }
        }

        return existingQuoteProductKeys;
    }

    private static void validateDuplicateProducts(List<QuoteLineItem> qlis, Map<Id, Id> pbeToProduct2, Set<String> existingQuoteProductKeys) {
        // We add QuoteLineItems from the batch here if their QuoteProduct Key pair is unique (first seen)
        Map<String, QuoteLineItem> seenQLIs = new Map<String, QuoteLineItem>();
        // We add QuoteId-ProductId string pair here if an error has already been added, only applies to keys that are unique and thus have been added to the seenQLIs Map
        Set<String> qliHits = new Set<String>();

        for (QuoteLineItem qli : qlis) {
            String quoteProductKey = qli.QuoteId + '-' + pbeToProduct2.get(qli.PricebookEntryId);

            // Does the key exist in the database?
            if (existingQuoteProductKeys.contains(quoteProductKey)) {
                qli.addError(DUPLICATE_DATABASE_ERROR);
            }
            // Does the key exist within the batch?
            else if (seenQLIs.containsKey(quoteProductKey)) {
                qli.addError(DUPLICATE_BATCH_ERROR);

                // Have we added an error to the first seen matching key yet?
                if (!qliHits.contains(quoteProductKey)) {
                    seenQLIs.get(quoteProductKey).addError(DUPLICATE_BATCH_ERROR);

                    qliHits.add(quoteProductKey);
                }
            // No matches? Then key is unique! add it to our watchlist for the next records
            } else {
                seenQLIs.put(quoteProductKey, qli);
            }
        }
    }
    

}