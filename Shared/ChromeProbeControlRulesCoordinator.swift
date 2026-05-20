import Foundation

/// Host/extension coordinator for epoch-scoped probe control rules (build 58).
/// macOS: `NEFilterControlProvider` is unavailable; the data provider applies rules via `applySettings`.
enum ChromeProbeControlRulesCoordinator {
    /// Persists probe rules to `/Users/Shared` (host and extension).
    static func updateFilter(
        withRules payload: ChromeProbeControlRulesFile.Payload,
        source: String
    ) {
        ChromeProbeControlRulesFile.write(payload)
        ChromeProbeControlRuleState.reloadFromDisk()
        // #region agent log
        AgentDebugLog.write(
            hypothesisId: "H58",
            location: "ChromeProbeControlRulesCoordinator.updateFilter",
            message: "chrome_control_provider_rules_persisted",
            data: [
                "epoch": payload.blockingEpoch,
                "ruleCount": String(payload.probeIPs.count),
                "rulesGeneration": String(payload.rulesGeneration),
                "source": source,
            ],
            runId: "post-fix-v25"
        )
        // #endregion
    }

    /// Extension `startFilter`: reload disk rules written by the host before bounce.
    static func loadRulesOnExtensionStart(vendorConfiguration: [String: Any]?) {
        let vendorEpoch = (vendorConfiguration?["blockingEpoch"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let generation = vendorConfiguration?["controlRulesGeneration"]
        // #region agent log
        AgentDebugLog.write(
            hypothesisId: "H58",
            location: "ChromeProbeControlRulesCoordinator.loadRulesOnExtensionStart",
            message: "chrome_control_provider_start",
            data: [
                "blockingEpoch": vendorEpoch ?? "",
                "controlRulesGeneration": String(describing: generation ?? "nil"),
            ],
            runId: "post-fix-v25"
        )
        // #endregion
        guard let disk = ChromeProbeControlRulesFile.read() else {
            ChromeProbeControlRuleState.reloadFromDisk()
            return
        }
        let sharedEpoch = BlockerSharedStateFile.read()?.blockingEpoch?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let sharedEpoch, !sharedEpoch.isEmpty, disk.blockingEpoch != sharedEpoch {
            let adopted = ChromeProbeControlRulesFile.Payload(
                blockingEpoch: sharedEpoch,
                probeIPs: disk.probeIPs,
                rulesGeneration: disk.rulesGeneration,
                lastUpdatedAtReference: Date().timeIntervalSinceReferenceDate
            )
            updateFilter(withRules: adopted, source: "extension_start_rekey_shared_epoch")
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H58",
                location: "ChromeProbeControlRulesCoordinator.loadRulesOnExtensionStart",
                message: "extension_start_rules_rekeyed_to_shared_epoch",
                data: [
                    "fileEpoch": disk.blockingEpoch,
                    "sharedEpoch": sharedEpoch,
                    "probeIPCount": String(disk.probeIPs.count),
                ],
                runId: "post-fix-v27"
            )
            DebugSessionLog594ccb.write(
                hypothesisId: "H7",
                location: "ChromeProbeControlRulesCoordinator.loadRulesOnExtensionStart",
                message: "extension_start_rules_rekeyed_to_shared_epoch",
                data: [
                    "fileEpoch": disk.blockingEpoch,
                    "sharedEpoch": sharedEpoch,
                    "probeIPCount": String(disk.probeIPs.count),
                ],
                runId: "post-fix"
            )
            // #endregion
            return
        }
        if let vendorEpoch, !vendorEpoch.isEmpty, disk.blockingEpoch != vendorEpoch {
            let vendorGen: UInt64 = {
                if let n = generation as? NSNumber { return n.uint64Value }
                if let g = generation as? UInt64 { return g }
                return disk.rulesGeneration
            }()
            let vendorProbeIPs = Self.probeIPLiterals(from: vendorConfiguration)
            let probeIPs = vendorProbeIPs.isEmpty ? disk.probeIPs : vendorProbeIPs
            let probeSource = vendorProbeIPs.isEmpty ? "file" : "vendor"
            let adopted = ChromeProbeControlRulesFile.Payload(
                blockingEpoch: vendorEpoch,
                probeIPs: probeIPs,
                rulesGeneration: vendorGen,
                lastUpdatedAtReference: Date().timeIntervalSinceReferenceDate
            )
            ChromeProbeControlRuleState.adoptPayload(adopted)
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H-D",
                location: "ChromeProbeControlRulesCoordinator.loadRulesOnExtensionStart",
                message: "extension_start_rules_vendor_adopt",
                data: [
                    "vendorEpoch": vendorEpoch,
                    "fileEpoch": disk.blockingEpoch,
                    "rulesGeneration": String(vendorGen),
                    "probeIPSource": probeSource,
                    "probeIPCount": String(probeIPs.count),
                ],
                runId: "b66"
            )
            DebugSessionLog81bf96.write(
                hypothesisId: "H-G",
                location: "ChromeProbeControlRulesCoordinator.loadRulesOnExtensionStart",
                message: "extension_start_rules_vendor_adopt",
                data: [
                    "vendorEpoch": vendorEpoch,
                    "fileEpoch": disk.blockingEpoch,
                    "rulesGeneration": String(vendorGen),
                    "probeIPSource": probeSource,
                    "probeIPCount": String(probeIPs.count),
                ],
                runId: "b66"
            )
            // #endregion
            return
        }
        updateFilter(withRules: disk, source: "extension_start")
    }

    private static func probeIPLiterals(from vendorConfiguration: [String: Any]?) -> [String] {
        guard let raw = vendorConfiguration?["probeIPLiterals"] as? [String] else {
            return []
        }
        return raw.compactMap { BlockerIPLiteralCanonical.canonical($0) }
    }
}
