/**
 * Copyright (c) 2016, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root  or https://opensource.org/licenses/BSD-3-Clause
 */
public class AppConstants {
    public static final String QUALIFIED_API_NAME_ATTRIBUTE = 'QualifiedApiName';
    public static final String FULL_NAME_ATTRIBUTE = 'FullName';
    public static final String LABEL_ATTRIBUTE = 'Label';
    public static final String DEV_NAME_ATTRIBUTE = 'DeveloperName';
    public static final String DESC_ATTRIBUTE = 'Description';
    public static final String MDT_SUFFIX = '__mdt';

    public static final String CS_NAME_ATTRIBUTE = 'Name';
    public static final String SELECT_STRING = 'Select type';
    public static final String LEAD_QUARANTINE = 'Quarantine';

    public static final String HEADER_MISSING_DEVNAME_AND_LABEL =
        'Header must contain at least one of these two fields - ' +
        DEV_NAME_ATTRIBUTE +
        ', ' +
        LABEL_ATTRIBUTE +
        '.';

    // Do not change value for ERROR_UNAUTHORIZED_ENDPOINT
    public static final String ERROR_UNAUTHORIZED_ENDPOINT = 'Unauthorized endpoint, please check Setup';

    public static final String AM_NAME = 'Account Manager';
    public static final String CSAM_NAME = 'Enterprise Account Manager';
    
    public static final String PSE_NAME = 'Pre-Sales Engineer';
    public static final String TSE_NAME = 'Technical Sales Engineer';

    public static final String WEST_COAST_CONTACT_DEV_NOTE = 'Something went wrong updating a contact';
    public static final String WEST_COAST_ACCOUNT_DEV_NOTE = 'Something went wrong updating an account';
    public static final String WEST_COAST_BDR_GROUP = '00G3u000002WqCvEAK';
    public static final String BDR_NAME = 'BDR';
    public static final Set<String> WEST_COAST_STATES = new Set<String>{
        'California',
        'Oregon',
        'Washington',
        'Nevada',
        'Alaska',
        'Hawaii'
    };
    public static final String API_USER = '0056A000002S1sMQAS';
    public static final String SALES_API_USER = '0053u000004K3dSAAS'; // User Managed Services Sales API User
    public static final String Xometry_Service_USER = '0053u000004p7LPAAY'; // Xometry Service User
    public static final String Xometry_Workcenter_USER = '005Dp000003PutwIAC'; // Xometry Workcenter
    public static final String GNO_HOUSE_USER = '0053u000004J1DQAA0';
    public static final String SALES_HOUSE_USER = '0053u000003JRWIAA4'; // This is also referred to as the Success Team.
    public static final String SUPPLIES_HOUSE_USER = '0053u000004JRcRAAW';
    public static final String P21_XOM_CUSTOMER_ID = '15077';
    public static final String CPC_HOUSE_USER = '005Dp0000017XEGIA2';

    public static final List<String> HOUSE_USERS_TO_EXCLUDE_FOR_SALES_OWNERSHIP = new List<String>{
        API_USER,
        SALES_API_USER,
        SUPPLIES_HOUSE_USER,
        CPC_HOUSE_USER
    };

    public static final Set<String> MGMT_QUEUES = new Set<String>{
        'Case Management Queue',
        'Automotive',
        'Atomic Rocks',
        'Spacetechs',
        'First Impressions',
        'Impodsters'
    };
    public static final Set<String> GENERAL_QUEUES = new Set<String>{ 'CPC Support' };
    public static final Set<String> PSE_QUEUES = new Set<String>{ 'Pre-Sales Engineering Queue' };

    public static final Set<String> MGMT_ROLES = new Set<String>{ 'DFM', 'CaseMgmt' };
    public static final Set<String> GENERAL_ROLES = new Set<String>{ 'Service' };
    public static final Set<String> PSE_ROLES = new Set<String>{ 'PSE' };
    public static final Set<String> jobClosedStringSet = new Set<String>{
        'Cancelled',
        'Expired',
        'Rejected',
        'Rescinded'
    };

    //ACCOUNT RECORD TYPES
    public static ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Customer')
        .getRecordTypeID();

    //OPPORTUNITY RECORD TYPES
    public static final ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    public static final Id oppSellerMarketplaceRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();

    //CASE RECORD TYPES
    public static final ID casePSERecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('PSE_Case')
        .getRecordTypeId();
    public static final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('CaseMgmt')
        .getRecordTypeId();
    public static final ID caseGeneralSupportRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('GeneralSupportCase')
        .getRecordTypeId();
    public static final ID caseSellerMarketPlaceRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('SellerMarketplace')
        .getRecordTypeId();
    public static final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeId();
    public static final ID collectionsRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('Collections')
        .getRecordTypeId();
    public static final ID caseFinServRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('FinServ')
        .getRecordTypeId();
    public static final ID nyopRTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('NYOP_Case')
        .getRecordTypeID();
    public static final ID caseSourcingRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('Sourcing')
        .getRecordTypeId();

    public static final Map<String, ID> ROLE_NAME_TO_CASE_RTYPE_MAP = new Map<String, ID>{
        'Service' => caseGeneralSupportRTypeId,
        'CaseMgmt' => caseManagementRTypeId,
        'DFM' => caseManagementRTypeId,
        'PSE' => casePSERecordTypeId,
        'Seller Service' => caseSellerMarketPlaceRTypeId,
        'Seller Marketplace Service' => caseSellerMarketPlaceRTypeId
    };

    public static final Map<String, ID> QUEUE_NAME_TO_CASE_RTYPE_MAP = new Map<String, ID>{
        //Case Management / DFM
        'Automotive' => caseManagementRTypeId,
        'Atomic Rocks' => caseManagementRTypeId,
        'Spacetechs' => caseManagementRTypeId,
        'First Impressions' => caseManagementRTypeId,
        'Impodsters' => caseManagementRTypeId,
        //General
        'CPC Support' => caseGeneralSupportRTypeId,
        //PSE
        'Pre-Sales Engineering Queue' => casePSERecordTypeId,
        //Marketplace
        'Seller Service' => caseSellerMarketPlaceRTypeId,
        'Seller Marketplace Service' => caseSellerMarketPlaceRTypeId
    };

    public static final List<ID> CASE_RECORD_TYPE_SWITCHING_EXCLUSIONS = new List<ID>{
        caseSellerMarketPlaceRTypeId,
        caseFinServRTypeId
    };

    public static final List<String> CASE_TYPE_SWITCHING_EXCLUSIONS = new List<String>{
        'Large Order Review',
        'Technical Review'
    };

    public static final List<String> CASE_CLOSED_STATUSES = new List<String>{
        'Closed',
        'Solved',
        'Merged',
        'CM/DFM Team Returned Quote',
        'NYOP Rejected'
    };

    public static final List<String> OPS_ORDER_COMPLETED_STATUSES = new List<String>{
        'Picked-Up by Customer',
        'Shipped',
        'Delivered'
    };

    public static final List<String> JOB_COMPLETED_STATUSES = new List<String>{ 'Completed', 'Vendor Completed' };
    public static final String QSRC_Punchout = 'Punchout';

    public static final DateTime pseLaunchTime = datetime.newInstanceGMT(2021, 5, 20, 0, 0, 0);
    public static final Date oppOwnerStampLaunchTime = Date.newInstance(2023, 1, 1);

    public static set<String> getSystemUsersIdSet()
    {
        Set<String> systemUserIdSet = new Set<String>();
        systemUserIdSet.add(AppConstants.API_USER);
        systemUserIdSet.add(AppConstants.SALES_API_USER);
        systemUserIdSet.add(AppConstants.Xometry_Service_USER);
        systemUserIdSet.add(AppConstants.Xometry_Workcenter_USER);

        return systemUserIdSet;
    }
}