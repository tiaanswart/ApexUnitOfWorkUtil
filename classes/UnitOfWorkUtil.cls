/**
 * @author       Tiaan Swart (tswart@deloitte.co.nz)
 * @date         2019-04-07
 * @description  UnitOfWorkUtil
 * 
 * CHANGE LOG
 * 2019-04-07 - Initial Setup of UnitOfWorkUtil
 **/
public with sharing class UnitOfWorkUtil {

    // We need a structure to process from
    @TestVisible
    private static Map<String, SObjectField> uowObjectToExternalIdField {
        get {
            if (uowObjectToExternalIdField == null) {
                uowObjectToExternalIdField = new Map<String, SObjectField>();
            }
            return uowObjectToExternalIdField;
        }
        set;
    }

    // We need a map of objects to upsert
    @TestVisible
    private static Map<String, List<SObject>> uowUpsertObjects {
        get {
            if (uowUpsertObjects == null) {
                uowUpsertObjects = new Map<String, List<SObject>>();
            }
            return uowUpsertObjects;
        }
        set;
    }

    // We need a map of objects to delete
    @TestVisible
    private static Map<String, List<SObject>> uowDeleteObjects {
        get {
            if (uowDeleteObjects == null) {
                uowDeleteObjects = new Map<String, List<SObject>>();
            }
            return uowDeleteObjects;
        }
        set;
    }

    // We need a map of objects to resolve relationships for
    @TestVisible
    private static Map<String, List<Map<String, Object>>> uowRelationships {
        get {
            if (uowRelationships == null) {
                uowRelationships = new Map<String, List<Map<String, Object>>>();
            }
            return uowRelationships;
        }
        set;
    }

    // Register a new uow object with an external id field to process
    public static void registerSObjectType(String theSObjectType, SObjectField externalIdField) {
        // If we don't have the object mapped
        if (!uowObjectToExternalIdField.containsKey(theSObjectType)) {
            uowObjectToExternalIdField.put(theSObjectType, externalIdField);
        }
        // If we don't have the object mapped for SObjects to Upsert
        if (!uowUpsertObjects.containsKey(theSObjectType)) {
            uowUpsertObjects.put(theSObjectType, new List<SObject>());
        }
        // If we don't have the object mapped for SObjects to Delete
        if (!uowDeleteObjects.containsKey(theSObjectType)) {
            uowDeleteObjects.put(theSObjectType, new List<SObject>());
        }
        // If we don't have the object mapped for Relationships
        if (!uowRelationships.containsKey(theSObjectType)) {
            uowRelationships.put(theSObjectType, new List<Map<String, Object>>());
        }
    }

    // Register a new or existing record to be upserted
    public static void registerUpsert(SObject theSObject) {
        // Get the object type
        String sObjectType = String.valueOf(theSObject.getSObjectType());
        // Add the object if we don't have it mapped
        registerSObjectType(sObjectType, null);
        // Add the object
        uowUpsertObjects.get(sObjectType).add(theSObject);
    }

    // Register a record to be deleted
    public static void registerDelete(SObject theSObject) {
        // Get the object type
        String sObjectType = String.valueOf(theSObject.getSObjectType());
        // Add the object if we don't have it mapped
        registerSObjectType(sObjectType, null);
        // Add the object
        uowDeleteObjects.get(sObjectType).add(theSObject);
    }

    // Register a relationship for a SObject and it's parent
    public static void registerRelationship(SObject theSObject, String relationshipField, SObject parentObject) {
        // Get the object type
        String sObjectType = String.valueOf(theSObject.getSObjectType());
        // Add the object if we don't have it mapped
        registerSObjectType(sObjectType, null);
        // Add the relationship
        uowRelationships.get(sObjectType).add(new Map<String, Object>{
            'theSObject' => theSObject,
            'relationshipField' => relationshipField,
            'parentObject' => parentObject
        });
    }

    // DML on generic List<SObject> only allowed for insert, update or delete
    // https://success.salesforce.com/ideaView?id=08730000000aNhVAAU
    private static void dynamicUpsert(List<SObject> recordsToUpsert, String theSObjectType, SObjectField theExternalIdField) {
        String listType = 'List<' + theSObjectType + '>';
        List<SObject> objectsToUpsert = (List<SObject>)Type.forName(listType).newInstance();
        objectsToUpsert.addAll(recordsToUpsert);
        // If we have an external id field
        if (theExternalIdField != null) {
            // Upsert with external id field
            Database.upsert(objectsToUpsert, theExternalIdField);
        } else {
            // Else upsert normally
            upsert objectsToUpsert;
        }
    }

    // Register a record to be deleted
    public static void commitWork() {
        // Set a SavePoint in case we have an exception
        Savepoint sp = Database.setSavepoint();
        try {
            // For each object type
            for (String theSObjectType : uowObjectToExternalIdField.keySet()) {
                // Get the external Id field
                SObjectField theExternalIdField = uowObjectToExternalIdField.get(theSObjectType);
                // Get the objects to process
                List<SObject> objectsToDelete = uowDeleteObjects.get(theSObjectType);
                List<SObject> objectsToUpsert = uowUpsertObjects.get(theSObjectType);
                List<Map<String, Object>> relationshipsToResolve = uowRelationships.get(theSObjectType);
                // If we have objects to delete, then delete them
                if (!objectsToDelete.isEmpty()) delete objectsToDelete;
                // If we have relationships to resolve
                if (!relationshipsToResolve.isEmpty()) {
                    // For each relationship
                    for (Map<String, Object> relationship : relationshipsToResolve) {
                        // Get the details
                        SObject theSObject = (SObject) relationship.get('theSObject');
                        String relationshipField = (String) relationship.get('relationshipField');
                        SObject parentObject = (SObject) relationship.get('parentObject');
                        // Resolve the relationship
                        theSObject.put(relationshipField, parentObject.Id);
                    }
                }
                // If we have objects to upsert
                if (!objectsToUpsert.isEmpty()) {
                    // Dynamically upsert the SObjects
                    dynamicUpsert(objectsToUpsert, theSObjectType, theExternalIdField);
                }
            }
            // After the commit clear everything
            uowObjectToExternalIdField = null;
            uowUpsertObjects = null;
            uowDeleteObjects = null;
            uowRelationships = null;
        } catch (Exception e) {
            // Roll back
            Database.rollback(sp);
            // Throw the exception again
            throw e;
        }
    }

}