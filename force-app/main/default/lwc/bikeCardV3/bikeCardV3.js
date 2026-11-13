import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// A1. Magický import standardních LDS operací (žádný Apex!)
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

// B1. LMS IMPORTY: Funkce publish, kontext a náš vlastní kanál (všimni si přípony __c)
import { publish, MessageContext } from 'lightning/messageService';
import BIKE_UPDATED_CHANNEL from '@salesforce/messageChannel/BikeUpdated__c';

// A2. Definice polí, která chceme stáhnout z databáze
const FIELDS = ['Bike__c.Name', 'Bike__c.Service_Status__c']

export default class BikeCardV3 extends LightningElement {
    @api recordId;
    bikeName;
    bikeServiceStatus;

    // B2. Získání kontextu sběrnice přes @wire
    @wire(MessageContext)
    messageContext;

    // ČTENÍ DAT: Použijeme @wire, ale předáme mu standardní LDS metodu getRecord
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wireBike({ error, data }) {
        if (data) {
            // LDS vrací data v trošku jiné struktuře (přes .fields a .value)
            this.bikeName = data.fields.Name.value;
            this.bikeServiceStatus = data.fields.Service_Status__c.value;
        } else if (error) {
            console.error('Chyba při načítání:', error);
        }
    }

    // ZÁPIS DAT: Tlačítko spustí tuto metodu
    handleStatusChange() {
        // Připravíme si objekt s daty, která chceme přepsat
        const fields = {};
        fields['Id'] = this.recordId;
        fields['Service_Status__c'] = 'Fixed';

        const recordInput = { fields };

        // Zápis přes standardní LDS funkci updateRecord
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Úspěch (V3)',
                        message: 'Status byl bleskově změněn čistě přes JS LDS!',
                        variant: 'success'
                    })
                );

                // B3. VYSÍLÁNÍ DO SBĚRNICE: Sestavíme payload (DTO) a pošleme ho do éteru
                const payload = {
                    recordId: this.recordId,
                    sourceComponent: 'BikeCardV3 (JS LDS)'              
                };
                publish(this.messageContext, BIKE_UPDATED_CHANNEL, payload);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Chyba při ukládání',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

    }
}