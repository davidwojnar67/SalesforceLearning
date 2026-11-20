import { LightningElement, api, wire } from 'lwc';

import getBikeDetails from '@salesforce/apex/BikeController.getBikeDetails';
import updateBikeServiceStatus from '@salesforce/apex/BikeController.updateBikeServiceStatus';
import getBikeParts from '@salesforce/apex/BikeController.getBikeParts';
import verifyBikeInRegistry from '@salesforce/apex/BikeController.verifyBikeInRegistry';

import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

// 1. LMS IMPORTY PRO PŘIJÍMAČ (lokální sběrnice čistě uvnitř jedné záložky prohlížeče – obdoba RxJS Subjectu)
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import BIKE_UPDATED_CHANNEL from '@salesforce/messageChannel/BikeUpdated__c';

// 2. EMPAPI IMPORTY PRO SERVEROVÝ PUSH (obdoba SignalR / WebSocket klienta nad protokolem CometD)
// Používáme JS aliasy ("as empSubscribe"), protože názvy subscribe/unsubscribe už máme zabrané z LMS výše.
import {
    subscribe as empSubscribe,
    unsubscribe as empUnsubscribe,
    onError as empOnError
} from 'lightning/empApi';

// 3. VLASTNÍ SDÍLENÝ SERVICE MODUL (bez .html šablony)
import { showToast, reduceErrors } from 'c/utils';

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
    isCheckingRegistry = false;

    // Držák na referenci @wire pro refreshApex
    wiredBikeResult;
    // Držák na aktivní LMS odběr (abychom ho mohli v Dispose odpojit)
    subscription = null;
    // Držák na aktivní empApi odběr (serverový streaming kanál Platform Eventů)
    empSubscription = null;
    // Všechny Platform Eventy mají pevně danou cestu ve tvaru /event/<API_Name>
    empChannelName = '/event/Bike_Service_Event__e';

    // 2. Získání kontextu sběrnice
    @wire(MessageContext)
    messageContext;

    // 3. ŽIVOTNÍ CYKLUS (obdoba ngOnInit): Zapnutí odposlechu při vykreslení komponenty do DOMu
    connectedCallback() {
        // A. Lokální LMS sběrnice (komunikace mezi LWC komponentami na téže stránce)
        if(!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                BIKE_UPDATED_CHANNEL,
                (message) => this.handleIncomingMessage(message)
            );
        }

        // B. Serverová Platform Event sběrnice (živý push ze Salesforce backendu)
        this.registerEmpErrorListener();
        this.subscribeToPlatformEvents();
    }

    // 4. ŽIVOTNÍ CYKLUS (obdoba ngOnDestroy / IDisposable): Úklid při opuštění stránky
    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }

        // Povinný úklid serverového streaming kanálu (Org má limit na počet otevřených CometD klientů)
        this.unsubscribeFromPlatformEvents();
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
                showToast(this, 'Úspěch!', 'Kolo bylo úspěšně označeno jako Opravené.', 'success');

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
                showToast(this, 'Chyba při ukládání', reduceErrors(error), 'error');
            });
    }

    // Zachycení CustomEventu z podřízené komponenty
    handlePartSelected(event) {
        // Payload z dítěte leží vždy v event.detail
        const { partName, checked } = event.detail;
        showToast(
            this,
            checked ? 'Úkon odškrtnut' : 'Úkon vrácen',
            `Položka: ${partName}`,
            'info'
        );
    }

    // Ukázka volání @api metody z rodiče na všechny děti v DOMu
    handleResetAllParts() {
        const childItems = this.template.querySelectorAll('c-bike-part-item');
        childItems.forEach(item => {
            item.resetCheck();
        });
    }

    handleRegistryCheck() {
        this.isCheckingRegistry = true;

        verifyBikeInRegistry({ bikeId: this.recordId })
            .then(result => {
                showToast(this, 'Registr ověřen', result.registryMessage, 'success');
                // 1. Překreslí V1 (invaliduje Apex Cache)
                refreshApex(this.wiredBikeResult);
                // 2. Překreslí V2 i V3 (invaliduje sdílenou LDS Cache)
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            })
            .catch(error => {
                showToast(this, 'Chyba integrace', reduceErrors(error), 'error');
            })
            .finally(() => {
                this.isCheckingRegistry = false;
            });
    }

    // =========================================================================
    // EMPAPI (PLATFORM EVENTS - ASYNCHRONNÍ PUSH ZE SERVERU)
    // =========================================================================

    subscribeToPlatformEvents() {
        // Ochrana proti duplicitnímu přihlášení
        if (this.empSubscription) {
            return;
        }

        // Callback, který se spustí pokaždé, když ze serveru přiletí nová událost
        const messageCallback = (response) => {
            // Optional chaining (?.) jako v C# – ochrana proti prázdné systémové zprávě
            const payload = response?.data?.payload;
            if (!payload) {
                return;
            }

            // Dvojitý filtr:
            // 1. Kanál je globální pro celý Org -> reagujeme jen na ID našeho konkrétního kola
            // 2. Ignorujeme startovací zprávy (FLOW_STATUS_PENDING) a čekáme až na finální PIPELINE_FINISHED
            if (payload.Bike_Id__c === this.recordId && payload.Event_Type__c === 'PIPELINE_FINISHED') {
                this.handlePipelineFinished(payload);
            }
        };

        // Parametr replayId = -1 znamená: "Nepřehrávej historii za posledních 72 hodin,
        // posílej mi jen nové události od okamžiku otevření stránky." (-2 by přehrálo celou historii).
        empSubscribe(this.empChannelName, -1, messageCallback).then((response) => {
            // Uložíme si token odběru, abychom ho mohli v disconnectedCallback zrušit
            this.empSubscription = response;
            console.log('V1 přihlášena k odběru Platform Eventů:', response.channel);
        });
    }

    async handlePipelineFinished(payload) {
        // 1. Překreslí V1: invaliduje mezipaměť vlastního Apex @wire(getBikeDetails)
        if (this.wiredBikeResult) {
            await refreshApex(this.wiredBikeResult);
        }

        // 2. Překreslí V2, V3 i standardní detaily záznamu: řekne sdílené klientské cache
        //    LDS (Lightning Data Service), že se záznam na serveru změnil -> překreslí celou stránku
        await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

        // 3. Vyparsujeme JSON payload ze zprávy a zobrazíme potvrzovací Toast
        let newStatus = 'Fixed';
        if (payload.Payload_Json__c) {
            try {
                const parsed = JSON.parse(payload.Payload_Json__c);
                if (parsed.newStatus) {
                    newStatus = parsed.newStatus;
                }
            } catch (e) {
                console.warn('Nepodařilo se parsovat Payload_Json__c:', e);
            }
        }

        showToast(
            this,
            'Asynchronní pipeline dokončena',
            `Externí registr ověřen na pozadí. Stav kola aktualizován na: ${newStatus}.`,
            'success'
        );
    }

    unsubscribeFromPlatformEvents() {
        if (this.empSubscription) {
            empUnsubscribe(this.empSubscription, () => {
                console.log('V1 odhlášena z odběru Platform Eventů.');
            });
            this.empSubscription = null;
        }
    }

    registerEmpErrorListener() {
        // Zachytí chyby CometD spojení (např. výpadek sítě nebo expiraci session)
        empOnError((error) => {
            console.error('Chyba empApi streaming kanálu:', JSON.stringify(error));
        });
    }
}