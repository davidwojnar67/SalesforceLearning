import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import BIKE_SERVICE_OBJECT from '@salesforce/schema/Bike_Service__c';
import SERVICE_TYPE_FIELD from '@salesforce/schema/Bike_Service__c.Service_Type__c';
import getServicesForBike from '@salesforce/apex/BikeServiceLogController.getServicesForBike';
import completeServiceLog from '@salesforce/apex/BikeServiceLogController.completeServiceLog';
import deleteServiceLog from '@salesforce/apex/BikeServiceLogController.deleteServiceLog';
import updateServiceLogs from '@salesforce/apex/BikeServiceLogController.updateServiceLogs';
import { showToast, reduceErrors } from 'c/utils';

const ROW_ACTIONS = [
    { label: 'Dokončit úkon', name: 'complete_service'},
    { label: 'Smazat', name: 'delete_service'}
];

export default class BikeServiceList extends LightningElement {
    @api recordId;

    services = [];
    draftValues = [];
    picklistOptions = [];
    wiredServicesResult;
    refreshHandlerId;

    @wire(getObjectInfo, { objectApiName: BIKE_SERVICE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: SERVICE_TYPE_FIELD
    })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.picklistOptions = data.values.map((item) => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            showToast(this, 'Chyba při načítání číselníku', reduceErrors(error), 'error');
        }
    }

    @wire(getServicesForBike, { bikeId: '$recordId' })
    wiredServices(result) {
        this.wiredServicesResult = result;

        if (result.data) {
            this.services = result.data;
        } else if (result.error) {
            this.services = [];
            showToast(this, 'Chyba při načítání servisů', reduceErrors(result.error), 'error');
        }
    }

    connectedCallback() {
        this.refreshHandlerId = registerRefreshHandler(this, this.handleRefresh);
    }

    disconnectedCallback() {
        unregisterRefreshHandler(this.refreshHandlerId);
    }

    get columns() {
        return [
            { label: 'Kód', fieldName: 'Name', type: 'text', initialWidth: 110 },
            { 
                label: 'Typ servisu',
                fieldName: 'Service_Type__c',
                type: 'picklist',
                editable: true,
                typeAttributes: {
                    placeholder: 'Vyberte typ servisu',
                    options: this.picklistOptions,
                    value: { fieldName: 'Service_Type__c' },
                    context: { fieldName: 'Id' }
                }
            },
            {
                label: 'Cena',
                fieldName: 'Cost__c',
                type: 'currency',
                editable: true,
                typeAttributes: { currencyCode: 'CZK' }
            },
            { label: 'Hotovo', fieldName: 'Is_Completed__c', type: 'boolean', initialWidth: 90 },
            { label: 'Datum dokončení', fieldName: 'Completed_Date__c', type: 'date-local' },
            {
                type: 'action',
                typeAttributes: { rowActions: ROW_ACTIONS }
            }
        ];
    }

    get hasServices() {
        return this.services && this.services.length > 0;
    }

    async handleSave(event) {
        const updatedFields = event.detail.draftValues;

        try {
            await updateServiceLogs({ services: updatedFields });
            showToast(this, 'Uloženo', 'Změny servisních úkonů byly uloženy', 'success');

            this.draftValues = [];
            await refreshApex(this.wiredServicesResult);
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (error) {
            showToast(this, 'Chyba při ukládání', reduceErrors(error), 'error');
        }
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'complete_service') {
            if (row.Is_Completed__c) {
                showToast(this, 'Info', 'Tento servisní úkon je již dokončený.', 'info');
                return;
            }

            try {
                await completeServiceLog({ serviceId: row.Id });
                showToast(this, 'Hotovo', `Úkon "${row.Service_Type__c}" byl dokončen`, 'success');

                await refreshApex(this.wiredServicesResult);
                await notifyRecordUpdateAvailable([{ recordId: this.recordId }])
            } catch (error) {
                showToast(this, 'Chyba při dokončení', reduceErrors(error), 'error');
            }
        } else if (actionName === 'delete_service') {
            try {
                await deleteServiceLog({ serviceId: row.Id });
                showToast(this, 'Smazáno', `Úkon "${row.Service_Type__c}" byl smazán`, 'success');

                await refreshApex(this.wiredServicesResult);
                await notifyRecordUpdateAvailable([{ recordId: this.recordId }])
            } catch (error) {
                showToast(this, 'Chyba při mazání', reduceErrors(error), 'error');
            }
        }
    }
    
    handleRefresh() {
        return new Promise((resolve) => {
            if (this.wiredServicesResult) {
                refreshApex(this.wiredServicesResult).finally(() => resolve(true));
            } else {
                resolve(true);
            }
        });
    }

    // // Simulace pádu
    // connectedCallback() {
    //     console.log('[BikeServiceList] connectedCallback');
    //     throw new Error('Simulovaná chyba při vykreslování seznamu servisů!');
    // }

    // // Pokus: Řízená překreslovací smyčka
    // // [BikeServiceList] Render č. 561415 aura_prod. js: 108
    // renderCount = 0;

    // renderedCallback() {
    //     console.log('[BikeServiceList] Render č. ', this.renderCount);
    //     this.renderCount++;
    // }
}