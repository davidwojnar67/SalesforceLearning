import { LightningElement, api, wire } from 'lwc';

import getBikeDetails from '@salesforce/apex/BikeController.getBikeDetails';
import updateBikeServiceStatus from '@salesforce/apex/BikeController.updateBikeServiceStatus';
import getBikeParts from '@salesforce/apex/BikeController.getBikeParts';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

// 1. LMS IMPORTY PRO PŘIJÍMAČ
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import BIKE_UPDATED_CHANNEL from '@salesforce/messageChannel/BikeUpdated__c';

import verifyBikeInRegistry from '@salesforce/apex/BikeController.verifyBikeInRegistry';

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

    // Držák na referenci @wire pro refreshApex
    wiredBikeResult;

    // Držák na aktivní odběr (abychom ho mohli v Dispose odpojit)
    subscription = null;

    // 2. Získání kontextu sběrnice
    @wire(MessageContext)
    messageContext;

    // 3. ŽIVOTNÍ CYKLUS: Zapnutí odposlechu při vykreslení komponenty do DOMu
    connectedCallback() {
        if(!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                BIKE_UPDATED_CHANNEL,
                (message) => this.handleIncomingMessage(message)
            );
        }
    }

    // 4. ŽIVOTNÍ CYKLUS: Úklid (IDisposable pattern) při opuštění stránky
    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // 5. ZPRACOVÁNÍ ZPRÁVY ZE SBĚRNICE
    handleIncomingMessage(message) {
        // Ověříme, že se zpráva týká našeho Kola (ochrana při otevření více tabů v konzoli)
        if (message.recordId === this.recordId) {
            console.log(`V1 zachytila LMS zprávu z: ${message.sourceComponent}. Spouštím refreshApex...`);
            refreshApex(this.wiredBikeResult);
        }
    }

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

    // Zachycení CustomEventu z podřízené komponenty
    handlePartSelected(event) {
        // Payload z dítěte leží vždy v event.detail
        const { partName, checked } = event.detail;

        this.dispatchEvent(
            new ShowToastEvent({
                title: checked ? 'Úkon odškrtnut' : 'Úkon vrácen',
                message: `Položka: ${partName}`,
                variant: 'info'
            })
        );
    }

    // Ukázka volání @api metody z rodiče na všechny děti v DOMu
    handleResetAllParts() {
        const childItems = this.template.querySelectorAll('c-bike-part-item');
        childItems.forEach(item => {
            item.resetCheck();
        });
    }


    isCheckingRegistry = false;

    handleRegistryCheck() {
        this.isCheckingRegistry = true;

        verifyBikeInRegistry({ bikeId: this.recordId })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Registr ověřen',
                        message: result.registryMessage,
                        variant: 'success'
                    })
                );

                // 1. Překreslí V1 (invaliduje Apex Cache)
                refreshApex(this.wiredBikeResult);
                // 2. Překreslí V2 i V3 (invaliduje sdílenou LDS Cache)
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Chyba integrace',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isCheckingRegistry = false;
            });
    }
}