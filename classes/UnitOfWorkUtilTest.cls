/**
 * @author       Tiaan Swart (tswart@deloitte.co.nz)
 * @date         2019-04-07
 * @description  UnitOfWorkUtilTest
 * 
 * CHANGE LOG
 * 2019-04-07 - Initial Setup of UnitOfWorkUtilTest
 **/
@IsTest
private class UnitOfWorkUtilTest {

    @TestSetup
    static void testSetup() {

        List<Account> theAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            theAccounts.add(new Account(Name='Account Nr '+i, ExternalId__c='Account Nr '+i));
        }
        insert theAccounts;

        List<Contact> theContacts = new List<Contact>();
        for (Account theAccount : theAccounts) {
            for (Integer i = 0; i < 5; i++) {
                theContacts.add(new Contact(FirstName='Contact Nr '+i, LastName='Test', AccountId=theAccount.Id));
            }
        }
        insert theContacts;

    }

    @IsTest
    static void testDeleteBehavior() {

        Map<Id, Account> theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource FROM Account]);
        System.assertEquals(5, theExistingAccounts.size(), 'Expected 5 existing accounts');

        Map<Id, Contact> theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(25, theExistingContacts.size(), 'Expected 25 existing contacts');

        Test.startTest();

        for (Contact theContact : theExistingContacts.values()) {
            UnitOfWorkUtil.registerDelete(theContact);
        }

        System.assertEquals(1, UnitOfWorkUtil.uowObjectToExternalIdField.keySet().size(), 'Expected to have 1 UOW Object');
        System.assertEquals('Contact', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[0], 'Expected the first UOW object to be "Contact"');
        System.assertEquals(1, UnitOfWorkUtil.uowUpsertObjects.size(), 'Expected to have 1 UOW upsert mapping');
        System.assertEquals(1, UnitOfWorkUtil.uowDeleteObjects.size(), 'Expected to have 1 UOW delete mapping');
        System.assertEquals(1, UnitOfWorkUtil.uowRelationships.size(), 'Expected to have 1 UOW relationship mapping');
        System.assertEquals(0, UnitOfWorkUtil.uowUpsertObjects.get('Contact').size(), 'Expected to have 0 UOW records to be upserted');
        System.assertEquals(25, UnitOfWorkUtil.uowDeleteObjects.get('Contact').size(), 'Expected to have 25 UOW records to be deleted');
        System.assertEquals(0, UnitOfWorkUtil.uowRelationships.get('Contact').size(), 'Expected to have 0 UOW relationships to be resolved');

        for (Account theAccount : theExistingAccounts.values()) {
            UnitOfWorkUtil.registerDelete(theAccount);
        }

        System.assertEquals(2, UnitOfWorkUtil.uowObjectToExternalIdField.keySet().size(), 'Expected to have 2 UOW Objects');
        System.assertEquals('Account', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[1], 'Expected the second UOW object to be "Account"');
        System.assertEquals(2, UnitOfWorkUtil.uowUpsertObjects.size(), 'Expected to have 2 UOW upsert mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowDeleteObjects.size(), 'Expected to have 2 UOW delete mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowRelationships.size(), 'Expected to have 2 UOW relationship mappings');
        System.assertEquals(0, UnitOfWorkUtil.uowUpsertObjects.get('Account').size(), 'Expected to have 0 UOW records to be upserted');
        System.assertEquals(5, UnitOfWorkUtil.uowDeleteObjects.get('Account').size(), 'Expected to have 5 UOW records to be deleted');
        System.assertEquals(0, UnitOfWorkUtil.uowRelationships.get('Account').size(), 'Expected to have 0 UOW relationships to be resolved');

        UnitOfWorkUtil.commitWork();

        Test.stopTest();

        theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource FROM Account]);
        System.assertEquals(0, theExistingAccounts.size(), 'Expected 0 existing accounts');

        theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(0, theExistingContacts.size(), 'Expected 0 existing contacts');

    }

    @IsTest
    static void testInsertBehavior() {

        Map<Id, Account> theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource FROM Account]);
        System.assertEquals(5, theExistingAccounts.size(), 'Expected 5 existing accounts');

        Map<Id, Contact> theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(25, theExistingContacts.size(), 'Expected 25 existing contacts');

        Test.startTest();

        for (Integer i = 0; i < 5; i++) {
            Account theAccount = new Account(Name='Account Nr '+i);
            UnitOfWorkUtil.registerUpsert(theAccount);

            for (Integer ii = 0; ii < 5; ii++) {
                Contact theContact = new Contact(FirstName='Contact Nr '+i, LastName='Test');
                UnitOfWorkUtil.registerUpsert(theContact);
                UnitOfWorkUtil.registerRelationship(theContact, 'AccountId', theAccount);
            }
        }

        System.assertEquals(2, UnitOfWorkUtil.uowObjectToExternalIdField.keySet().size(), 'Expected to have 2 UOW Objects');
        System.assertEquals('Account', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[0], 'Expected the first UOW object to be "Account"');
        System.assertEquals('Contact', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[1], 'Expected the second UOW object to be "Contact"');
        System.assertEquals(2, UnitOfWorkUtil.uowUpsertObjects.size(), 'Expected to have 2 UOW upsert mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowDeleteObjects.size(), 'Expected to have 2 UOW delete mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowRelationships.size(), 'Expected to have 2 UOW relationship mappings');
        System.assertEquals(5, UnitOfWorkUtil.uowUpsertObjects.get('Account').size(), 'Expected to have 5 Account UOW records to be upserted');
        System.assertEquals(0, UnitOfWorkUtil.uowDeleteObjects.get('Account').size(), 'Expected to have 0 Account UOW records to be deleted');
        System.assertEquals(0, UnitOfWorkUtil.uowRelationships.get('Account').size(), 'Expected to have 0 Account UOW relationships to be resolved');
        System.assertEquals(25, UnitOfWorkUtil.uowUpsertObjects.get('Contact').size(), 'Expected to have 25 Contact UOW records to be upserted');
        System.assertEquals(0, UnitOfWorkUtil.uowDeleteObjects.get('Contact').size(), 'Expected to have 0 Contact UOW records to be deleted');
        System.assertEquals(25, UnitOfWorkUtil.uowRelationships.get('Contact').size(), 'Expected to have 25 Contact UOW relationships to be resolved');

        UnitOfWorkUtil.commitWork();

        Test.stopTest();

        theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource, (SELECT Id FROM Contacts) FROM Account]);
        System.assertEquals(10, theExistingAccounts.size(), 'Expected 10 existing accounts');

        theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(50, theExistingContacts.size(), 'Expected 50 existing contacts');

        for (Account theAccount : theExistingAccounts.values()) {
            System.assertEquals(5, theAccount.Contacts.size(), 'Expected each existing account to have 5 contacts');
        }

    }

    @IsTest
    static void testUpdateBehavior() {

        Map<Id, Account> theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource FROM Account]);
        System.assertEquals(5, theExistingAccounts.size(), 'Expected 5 existing accounts');

        Map<Id, Contact> theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(25, theExistingContacts.size(), 'Expected 25 existing contacts');

        Test.startTest();

        for (Account theAccount : theExistingAccounts.values()) {
            System.assert(String.isBlank(theAccount.AccountSource), 'Expected the existing account source to be blank');
            theAccount.AccountSource = 'Existing';
            UnitOfWorkUtil.registerUpsert(theAccount);
        }

        System.assertEquals(1, UnitOfWorkUtil.uowObjectToExternalIdField.keySet().size(), 'Expected to have 1 UOW Object');
        System.assertEquals('Account', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[0], 'Expected the first UOW object to be "Account"');
        System.assertEquals(1, UnitOfWorkUtil.uowUpsertObjects.size(), 'Expected to have 1 UOW upsert mapping');
        System.assertEquals(1, UnitOfWorkUtil.uowDeleteObjects.size(), 'Expected to have 1 UOW delete mapping');
        System.assertEquals(1, UnitOfWorkUtil.uowRelationships.size(), 'Expected to have 1 UOW relationship mapping');
        System.assertEquals(5, UnitOfWorkUtil.uowUpsertObjects.get('Account').size(), 'Expected to have 5 UOW records to be upserted');
        System.assertEquals(0, UnitOfWorkUtil.uowDeleteObjects.get('Account').size(), 'Expected to have 0 UOW records to be deleted');
        System.assertEquals(0, UnitOfWorkUtil.uowRelationships.get('Account').size(), 'Expected to have 0 UOW relationships to be resolved');

        for (Contact theContact : theExistingContacts.values()) {
            System.assertEquals(null, theContact.Birthdate, 'Expected the existing contact birthdate to be blank');
            theContact.Birthdate = Date.today();
            UnitOfWorkUtil.registerUpsert(theContact);
        }

        System.assertEquals(2, UnitOfWorkUtil.uowObjectToExternalIdField.keySet().size(), 'Expected to have 2 UOW Objects');
        System.assertEquals('Contact', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[1], 'Expected the second UOW object to be "Contact"');
        System.assertEquals(2, UnitOfWorkUtil.uowUpsertObjects.size(), 'Expected to have 2 UOW upsert mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowDeleteObjects.size(), 'Expected to have 2 UOW delete mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowRelationships.size(), 'Expected to have 2 UOW relationship mappings');
        System.assertEquals(25, UnitOfWorkUtil.uowUpsertObjects.get('Contact').size(), 'Expected to have 25 UOW records to be upserted');
        System.assertEquals(0, UnitOfWorkUtil.uowDeleteObjects.get('Contact').size(), 'Expected to have 0 UOW records to be deleted');
        System.assertEquals(0, UnitOfWorkUtil.uowRelationships.get('Contact').size(), 'Expected to have 0 UOW relationships to be resolved');

        UnitOfWorkUtil.commitWork();

        Test.stopTest();

        theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource FROM Account]);
        System.assertEquals(5, theExistingAccounts.size(), 'Expected 5 existing accounts');

        for (Account theAccount : theExistingAccounts.values()) {
            System.assertEquals('Existing', theAccount.AccountSource, 'Expected the existing account source to be "Existing"');
        }

        theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(25, theExistingContacts.size(), 'Expected 25 existing contacts');

        for (Contact theContact : theExistingContacts.values()) {
            System.assertEquals(Date.today(), theContact.Birthdate, 'Expected the existing contact birthdate to be today');
        }

    }

    @IsTest
    static void testExternalIdBehaviour() {

        Map<Id, Account> theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource, ExternalId__c FROM Account]);
        System.assertEquals(5, theExistingAccounts.size(), 'Expected 5 existing accounts');

        Map<Id, Contact> theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(25, theExistingContacts.size(), 'Expected 25 existing contacts');

        Test.startTest();

        UnitOfWorkUtil.registerSObjectType('Account', Account.ExternalId__c);

        for (Account theAccount : theExistingAccounts.values()) {
            System.assert(String.isNotBlank(theAccount.ExternalId__c), 'Expected the existing account external id not to be blank');
            System.assert(String.isBlank(theAccount.AccountSource), 'Expected the existing account source to be blank');
            theAccount.Id = null;
            theAccount.AccountSource = 'Existing';
            UnitOfWorkUtil.registerUpsert(theAccount);
        }

        System.assertEquals(1, UnitOfWorkUtil.uowObjectToExternalIdField.keySet().size(), 'Expected to have 1 UOW Object');
        System.assertEquals('Account', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[0], 'Expected the first UOW object to be "Account"');
        System.assertEquals(1, UnitOfWorkUtil.uowUpsertObjects.size(), 'Expected to have 1 UOW upsert mapping');
        System.assertEquals(1, UnitOfWorkUtil.uowDeleteObjects.size(), 'Expected to have 1 UOW delete mapping');
        System.assertEquals(1, UnitOfWorkUtil.uowRelationships.size(), 'Expected to have 1 UOW relationship mapping');
        System.assertEquals(5, UnitOfWorkUtil.uowUpsertObjects.get('Account').size(), 'Expected to have 5 UOW records to be upserted');
        System.assertEquals(0, UnitOfWorkUtil.uowDeleteObjects.get('Account').size(), 'Expected to have 0 UOW records to be deleted');
        System.assertEquals(0, UnitOfWorkUtil.uowRelationships.get('Account').size(), 'Expected to have 0 UOW relationships to be resolved');

        for (Contact theContact : theExistingContacts.values()) {
            System.assertEquals(null, theContact.Birthdate, 'Expected the existing contact birthdate to be blank');
            theContact.Birthdate = Date.today();
            UnitOfWorkUtil.registerUpsert(theContact);
        }

        System.assertEquals(2, UnitOfWorkUtil.uowObjectToExternalIdField.keySet().size(), 'Expected to have 2 UOW Objects');
        System.assertEquals('Contact', new List<String>(UnitOfWorkUtil.uowObjectToExternalIdField.keySet())[1], 'Expected the second UOW object to be "Contact"');
        System.assertEquals(2, UnitOfWorkUtil.uowUpsertObjects.size(), 'Expected to have 2 UOW upsert mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowDeleteObjects.size(), 'Expected to have 2 UOW delete mappings');
        System.assertEquals(2, UnitOfWorkUtil.uowRelationships.size(), 'Expected to have 2 UOW relationship mappings');
        System.assertEquals(25, UnitOfWorkUtil.uowUpsertObjects.get('Contact').size(), 'Expected to have 25 UOW records to be upserted');
        System.assertEquals(0, UnitOfWorkUtil.uowDeleteObjects.get('Contact').size(), 'Expected to have 0 UOW records to be deleted');
        System.assertEquals(0, UnitOfWorkUtil.uowRelationships.get('Contact').size(), 'Expected to have 0 UOW relationships to be resolved');

        UnitOfWorkUtil.commitWork();

        Test.stopTest();

        theExistingAccounts = new Map<Id, Account>([SELECT Name, AccountSource FROM Account]);
        System.assertEquals(5, theExistingAccounts.size(), 'Expected 5 existing accounts');

        for (Account theAccount : theExistingAccounts.values()) {
            System.assertEquals('Existing', theAccount.AccountSource, 'Expected the existing account source to be "Existing"');
        }

        theExistingContacts = new Map<Id, Contact>([SELECT Name, AccountId, Birthdate FROM Contact]);
        System.assertEquals(25, theExistingContacts.size(), 'Expected 25 existing contacts');

        for (Contact theContact : theExistingContacts.values()) {
            System.assertEquals(Date.today(), theContact.Birthdate, 'Expected the existing contact birthdate to be today');
        }

    }

}