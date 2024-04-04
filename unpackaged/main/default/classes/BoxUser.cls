public with sharing class BoxUser {
    public class CreateUserRequest{
        public String name;
        public String login;
        public String external_app_user_id;
        public String job_title;

        public boolean is_platform_access_only = true;
        public String role = 'user';
        public String language = 'en';
        public boolean is_sync_enabled = true;
        public boolean can_see_managed_users = true;
        public boolean is_external_collab_restricted = true;
        public boolean is_exempt_from_device_limits = true;
        public boolean is_exempt_from_login_verification = true;
        public String status = 'active';
    }

    public class Entry{
        @AuraEnabled public String type;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String login;
        @AuraEnabled public DateTime created_at;
        @AuraEnabled public DateTime modified_at;
        @AuraEnabled public String language;
        @AuraEnabled public String timezone;
        @AuraEnabled public long space_amount;
        @AuraEnabled public Integer space_used;
        @AuraEnabled public long max_upload_size;
        @AuraEnabled public String status;
        @AuraEnabled public String job_title;
        @AuraEnabled public String phone;
        @AuraEnabled public String address;
        @AuraEnabled public String avatar_url;
        // @AuraEnabled public List<Object> notification_email;
        @AuraEnabled public ContextInfo context_info;
        @AuraEnabled public String code;
        @AuraEnabled public String help_url;
        @AuraEnabled public String message;
        @AuraEnabled public String request_id;
    }

    public class Conflict{
        @AuraEnabled public String type;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String login;
    }
    
    public class ContextInfo{
        @AuraEnabled public List<Conflict> conflicts;
    }

    public class userResponse{
        public Integer total_count;
        public List<Entry> entries;
        public Integer intLimit;
        public Integer offset;
    }
}