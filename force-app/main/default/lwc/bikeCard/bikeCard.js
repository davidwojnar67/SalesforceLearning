import { LightningElement, api, wire } from 'lwc';

import getBikeDetails from '@salesforce/apex/BikeController.getBikeDetails';
import updateBikeServiceStatus from '@salesforce/apex/BikeController.updateBikeServiceStatus';
import getBikeParts from '@salesforce/apex/BikeController.getBikeParts';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import { refreshApex } from '@salesforce/apex';

export default class BikeCard extends LightningElement {

    // V LWC existují takzvané dekorátory. 
    // Nejznámější je @api. Když proměnnou označíš jako @api, říkáš tím systému:
    // "Tohle je veřejná vlastnost, kdokoliv zvenčí mi do ní může něco poslat."
    // A když tu proměnnou pojmenuješ přesně recordId,
    // samotný Salesforce do ní při načtení stránky automaticky vstříkne ID aktuálního záznamu.
    @api recordId;

    // Lokální proměnné, které bezpečně pošleme do HTML
    bikeName;
    bikeServiceStatus;
    errorMessage;

    bikePartsList = [];

    // V klasickém JavaScriptu (nebo tvém TypeScriptu v Angularu) bys pravděpodobně volal nějaké HTTP API,
    // čekal na Promise (.then()) a pak ručně ukládal výsledek do proměnné.
    // V LWC nám Salesforce dává reaktivní datový proud (Wire), který se o vše postará sám.

    // Magie LWC: Wire Service
    // Propojíme naši Apex metodu a předáme jí parametr 'bikeId', který Apex očekává.
    // Znak '$' znamená, že parametr je dynamický. Pokud se recordId změní, Apex se zavolá znovu.
    @wire(getBikeDetails, { bikeId: '$recordId' })
    wiredBike(result) { // TADY ZMĚNA: už neděláme { data, error }, chytáme celý objekt (nepřekresloval se Aktuální stav)
        this.wiredBikeResult = result;

        if (result.data) {
            this.bikeName = result.data.Name;
            this.bikeServiceStatus = result.data.Service_Status__c;
            this.errorMessage = undefined;
        } else if (result.error) {
            this.errorMessage = 'Nepodařilo se načíst data kola.';
            this.bikeName = undefined;
            this.bikeServiceStatus = undefined;
        }
    }

    @wire(getBikeParts, { bikeId: '$recordId' })
    wiredParts({ error, data }) {
        if (data) {
            this.bikePartsList = data;
        }
    }

    // bikeRecord; // Výsledek ze serveru se automaticky uloží do tohoto objektu

    // Všimni si, jak je ten kód krátký. Žádné volání API, žádné fetch, žádné chytání výjimek.
    // O to vše se stará ten dekorátor @wire. Objekt bikeRecord bude pod kapotou automaticky obsahovat dvě vlastnosti:
    // bikeRecord.data (pokud se to povede) a bikeRecord.error (pokud něco spadne).

    handleServiceStatusChange() {
        updateBikeServiceStatus({ bikeId: this.recordId, newBikeServiceStatus: 'Fixed'  })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Úspěch!',
                        message: 'Kolo bylo úspěšně označeno jako Opravené.',
                        variant: 'success'
                    })
                );

                // TOHLE PŘEKRESLÍ NÁŠ LWC PANEL V1 (Smaže Apex Cache)
                refreshApex(this.wiredBikeResult);

                // // 1. Vytvoření objektu
                // let zaznamKObnove = { recordId: this.recordId };
                // // 2. Vložení objektu do pole
                // let poleZaznamu = [ zaznamKObnove ];
                // // 3. Předání pole funkci
                // notifyRecordUpdateAvailable(poleZaznamu);

                // Řekneme systému, ať si obnoví paměť pro tohle konkrétní ID
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
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