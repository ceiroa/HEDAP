/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2015
* @group Affiliations
* @description Supports changing the record type of an account.
*/
public with sharing class AFFL_AccRecordType_TDTM extends TDTM_Runnable {
	
	/*******************************************************************************************************
    * @description Updates key affiliation lookups on contact, and any other primary affiliation of the new type.
    * @return dmlWrapper
    ********************************************************************************************************/
	public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
    
    	 DmlWrapper dmlWrapper = new DmlWrapper();
    	 
    	 if(newlist != null && newlist.size() > 0 && oldlist != null && oldlist.size() > 0) {
    	 	Integer i = 0;
    	 	for (SObject so : newlist) {
    	 		if(triggerAction == TDTM_Runnable.Action.AfterUpdate) {
	    	 		Account acc = (Account)so;
			        Account oldAcc = (Account)oldList[i];
			        
			        //When a user changes the record type of an Account, if that account was part of any primary affiliation, other primary 
			        //affiliations of the same type need to be unchecked, and the key affl lookup field on the contacts needs to be updated.
			        if(acc.RecordTypeId != oldAcc.RecordTypeId) {
			        	AFFL_MultiRecordTypeMapper afflMapper = new AFFL_MultiRecordTypeMapper(); 
			        	
			        	//Find the lookup field that matches the old record type
			        	String keyAfflFieldOldType = afflMapper.getKeyAfflFieldByAccRecordType(oldAcc.RecordTypeId);
			        	
			        	//Find the lookup field that matches the new record type
			        	String keyAfflFieldNewType = afflMapper.getKeyAfflFieldByAccRecordType(acc.RecordTypeId);
			        	
			        	//Find all contacts where that field was pointing to this account
			        	List<Contact> relatedContacts = Database.query('select ID from Contact where ' + keyAfflFieldOldType + '=\'' + acc.ID + '\'');
			        	
			        	for(Contact contact : relatedContacts) {
			        		contact.put(keyAfflFieldOldType, null);
			        		contact.put(keyAfflFieldNewType, acc.Id);
			        		dmlWrapper.objectsToUpdate.add(contact);
			        	}
			        }
    	 		}
		    }
		    i++;
    	 }
    	 return dmlWrapper;
    }
}