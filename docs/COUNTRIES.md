# Country searches

Most OSINT collections are built around US sources. northstar-osint adds a country layer: the `ns-country` menu, with searches tailored to each country's public records, and a **Countries** bookmark folder (one subfolder per country) delivered to Firefox and Brave by policy.

There are 17 countries plus an International pack, with 144 search types and 268 curated bookmarks in total.

## How ns-country works

1. Pick a country. The one you used last is at the top of the list. You can also go straight to one: `ns-country GB`.
2. Pick a search type and type your query.
3. A dialog shows any analysis (for phone numbers) and the query, which is now on your clipboard. Click OK, and `ns-country` opens, in your browser:
   - **targeted Google searches** that can always be pre-filled (court decisions, obituaries, news, regulator sites, complaints);
   - **registries pre-filled with your query** where the registry allows it (Companies House, ABN Lookup, KvK, Annuaire des Entreprises, the FAA register and others);
   - **registry search pages** for the rest. Many government registries are single-page apps or session-based forms that can't be pre-filled, so your query is **copied to the clipboard**: paste it with Ctrl/Cmd+V.
4. The query, every link opened, and any analysis go into the case folder (`~/Northstar/Cases/<case>/<country>/…`), and the search is logged in `audit.log`.

**Phone numbers** are analysed with Google's libphonenumber for every country: validity, region, original carrier and line type. They're then searched in all the common formats (`613-555-0142`, `(613) 555-0142`, `+1 613-555-0142`, …). The carrier shown is the *original* carrier for that number block, and numbers can be ported, so treat it as a lead. In the International pack, include the country code (`+44 …`).

`ns-canada` still works; it opens the Canada pack directly.

## Countries

| Country | Code | Search types | Bookmarks |
|---|---|---|---|
| International | `INT` | Sanctions & watchlists, Company (any country), Leaks & investigations, Phone number, Vessel (name, IMO or MMSI), Aircraft (registration), EU institutions, lobbying & tenders, Crypto address | 24 |
| Australia | `AU` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political donations & lobbying, Vehicle (VIN), Aircraft | 14 |
| Canada | `CA` | Person, Business / organization, Phone number, Address / postal code, Financial & regulatory check, Political contributions & lobbying, Vessel, Aircraft, Vehicle (VIN), Amateur radio call sign | 53 |
| France | `FR` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political & lobbying, Aircraft | 18 |
| Germany | `DE` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political & lobbying, Aircraft | 13 |
| Indonesia | `ID` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Aircraft | 6 |
| Ireland | `IE` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political donations & lobbying | 13 |
| Italy | `IT` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Vehicle (licence plate), Aircraft | 10 |
| Malaysia | `MY` | Person, Business / organization, Phone number, Address / property, Financial & regulatory check, Aircraft | 9 |
| Netherlands | `NL` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Vehicle (licence plate), Aircraft | 10 |
| New Zealand | `NZ` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political donations & interests, Vehicle (plate), Aircraft | 12 |
| Philippines | `PH` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Aircraft | 8 |
| Singapore | `SG` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Aircraft | 8 |
| Spain | `ES` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political & lobbying, Aircraft | 10 |
| Thailand | `TH` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Aircraft | 6 |
| United Kingdom | `GB` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political donations & interests, Vehicle (registration), Aircraft | 22 |
| United States | `US` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Political contributions & lobbying, Vessel, Aircraft (N-number), Vehicle (VIN), Amateur radio call sign | 26 |
| Vietnam | `VN` | Person, Business / organization, Phone number, Address / property, Courts & legal, Financial & regulatory check, Aircraft | 6 |

## Notes

- **Paid searches:** some registries charge per search or per document. Examples include OSB records and most provincial corporate profiles in Canada, PACER in the US, the AFSA bankruptcy register and PPSR in Australia, SSM e-Info in Malaysia, and Bizfile profiles in Singapore. The menu only opens search pages. Nothing is ever bought automatically.
- **Sites that block foreign visitors:** several government sites refuse connections from outside their country, including some in Australia, Indonesia, Thailand and Vietnam. If one won't load, it's usually that, not a dead link. Use a VPN exit in that country if your rules allow it.
- **Language:** registries in non-English-speaking countries are mostly in the local language. The browser's built-in translation works on most of them.
- **Privacy law:** registries publish data for specific purposes. Make sure your use is lawful and proportionate under the law that applies to you and to the data: GDPR in the EU and UK, PIPEDA in Canada, the Privacy Act in Australia and New Zealand, the PDPA in Singapore, Malaysia and Thailand, and so on.
- **Links change:** government sites reorganise often. Run `ns-linkcheck` periodically and open an issue or pull request for anything that has moved.

## Adding or improving a country

Each country is one JSON file in `config/countries/`, named after its ISO 3166-1 alpha-2 code (`gb.json`). No code changes are needed: `ns-country`, the bookmarks and the link checker pick it up automatically.

```json
{
  "code": "GB",
  "name": "United Kingdom",
  "phone_region": "GB",
  "searches": [
    {
      "label": "Business / organization",
      "prompt": "Company or organization name:",
      "links": [
        "https://find-and-update.company-information.service.gov.uk/search/companies?q={q}",
        "https://register.fca.org.uk/s/",
        "g:\"{q}\" (scam OR fraud OR complaint) UK"
      ],
      "note": "Optional text shown after the search."
    }
  ],
  "bookmarks": [
    {"name": "Corporate & Financial", "children": [
      {"name": "Companies House", "url": "https://find-and-update.company-information.service.gov.uk/"}
    ]}
  ]
}
```

| Field | Meaning |
|---|---|
| `phone_region` | Country used to read phone numbers written without `+code` (`null` for the International pack) |
| `links` | `https://…` URLs, with `{q}` where the query goes (it's URL-encoded for you), or `g:…` for a Google search of that text |
| `type: "phone"` | Makes a search a phone search. Its links can use `{e164}`, `{intl}`, `{national}`, `{alt}` (hyphenated national format) and `{digits}` |
| `transform` | Optional clean-up of the query: `upper`, `alnum` (letters and digits only), `callsign` (letters, digits and `/`), `digits` |
| `note` | Optional hint shown in the final dialog, such as "this registry charges per search" |

Before opening a pull request, run:

```bash
python3 lib/ns_country.py validate          # checks every pack's structure
./tools/ns-linkcheck config/countries/xx.json
```

Prefer official registries and regulators, then reputable public-interest sources. Public phone directories are fine; don't add people-search or data-broker sites.
