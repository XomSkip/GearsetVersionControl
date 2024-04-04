public class BoxError{

    public String type;
    public Integer status;
    public String code;
    public String help_url;
    public String message;
    public String request_id;
    public ContextInfo context_info;

    public class ContextInfo{
        public List<Error> errors;
    }

    public class Error{
        public String reason;
        public String name;
        public String message;
    }
}