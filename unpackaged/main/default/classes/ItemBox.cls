public with sharing class ItemBox {
    
    public class Entry{
        @AuraEnabled public String type;
        @AuraEnabled public String id;
        @AuraEnabled public String sequence_id;
        @AuraEnabled public String etag;
        @AuraEnabled public String name;
        @AuraEnabled public FileVersion file_version;
        @AuraEnabled public String sha1;
    }

    public class FileVersion{
        @AuraEnabled public String type;
        @AuraEnabled public String id;
        @AuraEnabled public String sha1;
    }

    public class Order{
        @AuraEnabled public String strby;
        @AuraEnabled public String direction;
    }

    public class Response{
        @AuraEnabled public Integer total_count;
        @AuraEnabled public List<Entry> entries;
        @AuraEnabled public Integer offset;
        @AuraEnabled public Integer intlimit;
        @AuraEnabled public List<Order> order;
    }
}