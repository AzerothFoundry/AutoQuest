# AutoQuest source

Upstream: https://github.com/Nelkel9023/AutoQuest
Pinned commit: fd349f1642c2fa2f452d8aadeaafbbbb4aa56b62
Upstream version: 1.2.0; Interface 11200.

Local compatibility changes: private chat output helper instead of unavailable print; Lua 5.0 table length instead of select; pending actions cancelled on dialogue close and recheck title/Shift/enabled on execution. Original README retained. Default automatic acceptance and turn-in enabled, multiple reward choice remains manual unless explicitly enabled via /aq reward. No OctoPawn dependency required.

Local 1.2.1 update: AutoQuestDB saved settings loaded after addon/variables events; Chinese options window via quest-log button and AutoQuest.ShowOptions; /aq with no arguments opens options. Slash/GUI use shared persisted settings; deferred accept/turn-in recheck individual enable flags.
The optional OctoPawn reward flag is also exposed in the options window; its default remains false.

Distribution note: upstream currently provides no explicit LICENSE. GitHub fork provenance is retained; do not include this modified addon in downloadable bundles until redistribution permission is confirmed.
