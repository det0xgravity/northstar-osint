# Canadian toolkit

Most OSINT collections are built around US sources. northstar-osint includes a dedicated Canadian layer: the `ns-canada` menu and seven Canadian bookmark folders, delivered to Firefox and Brave by policy.

## How ns-canada works

Many Canadian government registries are single-page apps or session-based forms, so a search can't be pre-filled from a link. For each search type, `ns-canada` therefore:

1. Opens **targeted Google searches** that *can* be deep-linked (court decisions, obituaries, news, government sites, complaints).
2. Opens the **relevant registries** on their search pages.
3. **Copies your query to the clipboard**, so filling each registry is just Ctrl/Cmd+V.
4. Writes `query.txt` to the case and logs the search in `audit.log`.

## Search types

| Search | Opens |
|---|---|
| **Person** | CanLII, obituaries (Legacy, InMemoriam, Dignity Memorial), LinkedIn Canada, major Canadian news, Canada Gazette, government sites, Canada411, GEDS |
| **Business / organization** | OpenCorporates (pre-filled), Corporations Canada, Ontario Business Registry, SEDAR+, CRA charities, FINTRAC MSB registry, CanLII, complaint/fraud search |
| **Phone number** | Region and line-type analysis (libphonenumber) shown in a dialog and saved; searches across all common formats, scam reports, and social/classified sites; Canada411; CNAC |
| **Address / postal code** | Google Maps and OpenStreetMap (pre-filled), exact-phrase search, OnLand, MPAC AboutMyProperty, Canada Post postal code lookup |
| **Financial & regulatory** | CSA National Registration Search, FINTRAC MSB registered and revoked lists, OSB bankruptcy/insolvency records, the Canadian sanctions list, securities-regulator enforcement searches, CanLII |
| **Political & lobbying** | Elections Canada contributions, Elections Ontario, Elections BC, Registry of Lobbyists |
| **Vessel** | Transport Canada vessel registration, LAC historic ship registration records (Collection Search) |
| **Aircraft** | Canadian Civil Aircraft Register, registration search |
| **Vehicle (VIN)** | NHTSA VIN decoder (pre-filled; decodes most Canadian-market vehicles), VIN search |
| **Amateur radio call sign** | QRZ (pre-filled), ISED amateur radio services, call-sign search |

**About phone analysis:** the carrier shown is the *original* carrier for that number block. Canadian numbers can be ported between carriers, so treat it as a lead, not a fact.

## Bookmark folders

| Folder | Highlights |
|---|---|
| Canada – Corporate & Financial | Corporations Canada, Ontario/BC/Quebec/Manitoba/Saskatchewan registries, OpenCorporates, SEDAR+, CSA registration, FINTRAC MSB (registered + revoked), OSB records, CRA charities, CIPO trademarks, sanctions list, Canadian Anti-Fraud Centre |
| Canada – Legal & Government | CanLII, Canada Gazette, GEDS, Open Government, federal contracts and grants, lobbyists, Elections Canada/Ontario/BC, Ontario salary disclosure, Library and Archives Canada |
| Canada – Licensed Professionals (ON) | Law Society, CPSO, CNO, PEO, RECO, FSRA |
| Canada – Property & Places | OnLand, MPAC, BC Assessment, Ontario GeoHub, NRCan Toporama, Canada Post |
| Canada – People & Communications | Canada411, CNAC, obituary sites, Canada's Missing, CIRA |
| Canada – Transport & Radio | Vessel registry, historic ship registrations, civil aircraft register, ISED spectrum and amateur radio, VIN decoder |

## Notes on Canadian sources

- **Paid searches:** some registries charge per search or per document, including OSB records, Ontario Business Registry documents, OnLand documents and most provincial corporate profiles. The menu only opens the search pages. Nothing is purchased automatically.
- **Ontario-heavy:** the professional-regulator folder covers Ontario. Contributions for other provinces are very welcome. See [CONTRIBUTING.md](../CONTRIBUTING.md).
- **Privacy law:** Canadian registries publish data for specific purposes. Make sure your use is lawful and proportionate under PIPEDA or the provincial law that applies to you.
- **Links change:** government sites reorganise often. Run `ns-linkcheck` periodically and open an issue or PR for anything that has moved.
