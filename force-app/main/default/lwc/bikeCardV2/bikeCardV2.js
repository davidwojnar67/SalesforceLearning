import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { publish, MessageContext } from 'lightning/messageService';
import BIKE_UPDATED_CHANNEL from '@salesforce/messageChannel/BikeUpdated__c';

export default class BikeCardV2 extends LightningElement {
    @api recordId;

    @wire(MessageContext)
    messageContext;

    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Uloženo',
                message: 'Data byla uložena přes LDS!',
                variant: 'success'
            })
        );

        // Notifikace pro Apex-driven komponenty
        publish(this.messageContext, BIKE_UPDATED_CHANNEL, {
            recordId: this.recordId,
            sourceComponent: 'BikeCardV2 (Edit Form)'
        });
    }
}