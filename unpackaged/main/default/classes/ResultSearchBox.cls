public with sharing class ResultSearchBox {
    
    public class CreatedBy{
        public String type;
        public String id;
        public String name;
        public String login;
    }

    public class Entry{
        public String type;
        public String id;
        public String sequence_id;
        public String etag;
        public String name;
        public String created_at;
        public String modified_at;
        public String description;
        public Integer size;
        public PathCollection path_collection;
        public CreatedBy created_by;
        public ModifiedBy modified_by;
        public Object trashed_at;
        public Object purged_at;
        public String content_created_at;
        public String content_modified_at;
        public OwnedBy owned_by;
        public SharedLink shared_link;
        public Object folder_upload_email;
        public Parent parent;
        public String item_status;
        public FileVersion file_version;
        public String sha1;
    }

    public class FileVersion{
        public String type;
        public String id;
        public String sha1;
    }

    public class ModifiedBy{
        public String type;
        public String id;
        public String name;
        public String login;
    }

    public class OwnedBy{
        public String type;
        public String id;
        public String name;
        public String login;
    }

    public class Parent{
        public String type;
        public String id;
        public Object sequence_id;
        public Object etag;
        public String name;
    }

    public class PathCollection{
        public Integer total_count;
        public List<Entry> entries;
    }

    public class Permissions{
        public boolean can_preview;
        public boolean can_download;
        public boolean can_edit;
    }

    public class Root{
        public Integer total_count;
        public List<Entry> entries;
        public Integer intlimit;
        public Integer offset;
    }

    public class SharedLink{
        public String url;
        public String download_url;
        public Object vanity_url;
        public Object vanity_name;
        public String effective_access;
        public String effective_permission;
        public boolean is_password_enabled;
        public Object unshared_at;
        public Integer download_count;
        public Integer preview_count;
        public String access;
        public Permissions permissions;
    }

}