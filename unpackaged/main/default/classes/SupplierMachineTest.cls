@isTest
public with sharing class SupplierMachineTest {
    @isTest
    public static void newSupplierMachine() {
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P0000';
        s.EmailAddress__c = 'supplier@gmail.com';
        insert s;

        Supplier_Machine__c mach = new Supplier_Machine__c();
        mach.machineID__c = '6116f568f8d105000951e08e-23374';
        mach.PartnerID__c = 'P0000';
        mach.MachineType__c = 'CNC Vertical Mill';
        mach.Quantity__c = 1;
        mach.Xaxis__c = 100;
        mach.Yaxis__c = 200;
        mach.Zaxis__c = 300;

        Test.startTest();
        insert mach;
        Test.stopTest();

        Supplier_Machine__c machineResult = [SELECT Id, Supplier__c FROM Supplier_Machine__c WHERE Id = :mach.Id][0];

        Supplier__c supplierResult = [SELECT Id, PartnerID__c FROM Supplier__c WHERE PartnerID__c = :s.PartnerID__c][0];

        System.assertEquals(
            supplierResult.Id,
            machineResult.Supplier__c,
            'The machine was associated to the wrong supplier'
        );
    }

    @isTest
    public static void newSupplierMachines_SameSupplier() {
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P0000';
        s.EmailAddress__c = 'supplier@gmail.com';
        insert s;

        List<Supplier_Machine__c> machineList = new List<Supplier_Machine__c>();

        Supplier_Machine__c mach1 = new Supplier_Machine__c();
        mach1.machineID__c = '6116f568f8d105000951e08e-23374';
        mach1.PartnerID__c = 'P0000';
        mach1.MachineType__c = 'CNC Vertical Mill';
        mach1.Quantity__c = 1;
        mach1.Xaxis__c = 100;
        mach1.Yaxis__c = 200;
        mach1.Zaxis__c = 300;
        machineList.add(mach1);

        Supplier_Machine__c mach2 = new Supplier_Machine__c();
        mach2.machineID__c = '6116f568f8d105000951e08e-23375';
        mach2.PartnerID__c = 'P0000';
        mach2.MachineType__c = 'Sheet Metal Brake';
        mach2.Quantity__c = 10;
        mach2.Xaxis__c = 100;
        mach2.Yaxis__c = 200;
        mach2.Zaxis__c = 300;
        machineList.add(mach2);

        Test.startTest();
        insert machineList;
        Test.stopTest();

        Supplier_Machine__c machine1Result = [SELECT Id, Supplier__c FROM Supplier_Machine__c WHERE Id = :mach1.Id][0];

        Supplier_Machine__c machine2Result = [SELECT Id, Supplier__c FROM Supplier_Machine__c WHERE Id = :mach2.Id][0];

        Supplier__c supplierResult = [SELECT Id, PartnerID__c FROM Supplier__c WHERE PartnerID__c = :s.PartnerID__c][0];

        System.assertEquals(
            supplierResult.Id,
            machine1Result.Supplier__c,
            'The first machine was associated to the wrong supplier'
        );
        System.assertEquals(
            supplierResult.Id,
            machine2Result.Supplier__c,
            'The second machine was associated to the wrong supplier'
        );
    }

    @isTest
    public static void newSupplierMachines_DifferentSuppliers() {
        Supplier__c s1 = new Supplier__c();
        s1.PartnerID__c = 'P0000';
        s1.EmailAddress__c = 'supplier1@gmail.com';
        insert s1;

        Supplier__c s2 = new Supplier__c();
        s2.PartnerID__c = 'P00001';
        s2.EmailAddress__c = 'supplier2@gmail.com';
        insert s2;

        List<Supplier_Machine__c> machineList = new List<Supplier_Machine__c>();

        Supplier_Machine__c mach1 = new Supplier_Machine__c();
        mach1.machineID__c = '6116f568f8d105000951e08e-23374';
        mach1.PartnerID__c = 'P0000';
        mach1.MachineType__c = 'CNC Vertical Mill';
        mach1.Quantity__c = 1;
        mach1.Xaxis__c = 100;
        mach1.Yaxis__c = 200;
        mach1.Zaxis__c = 300;
        machineList.add(mach1);

        Supplier_Machine__c mach2 = new Supplier_Machine__c();
        mach2.machineID__c = '6116f568f8d105000951e08e-23375';
        mach2.PartnerID__c = 'P00001';
        mach2.MachineType__c = 'Sheet Metal Brake';
        mach2.Quantity__c = 10;
        mach2.Xaxis__c = 100;
        mach2.Yaxis__c = 200;
        mach2.Zaxis__c = 300;
        machineList.add(mach2);

        Test.startTest();
        insert machineList;
        Test.stopTest();

        Supplier_Machine__c machine1Result = [SELECT Id, Supplier__c FROM Supplier_Machine__c WHERE Id = :mach1.Id][0];

        Supplier_Machine__c machine2Result = [SELECT Id, Supplier__c FROM Supplier_Machine__c WHERE Id = :mach2.Id][0];

        Supplier__c supplier1Result = [
            SELECT Id, PartnerID__c
            FROM Supplier__c
            WHERE PartnerID__c = :s1.PartnerID__c
        ][0];

        Supplier__c supplier2Result = [
            SELECT Id, PartnerID__c
            FROM Supplier__c
            WHERE PartnerID__c = :s2.PartnerID__c
        ][0];

        System.assertEquals(
            supplier1Result.Id,
            machine1Result.Supplier__c,
            'The machine was associated to the wrong supplier'
        );
        System.assertEquals(
            supplier2Result.Id,
            machine2Result.Supplier__c,
            'The machine was associated to the wrong supplier'
        );
    }
}