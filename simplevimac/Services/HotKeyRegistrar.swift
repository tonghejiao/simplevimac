//
//  HotKeyRegistrar.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/8.
//d

class HotKeyRegistrar {
    static func register(
        _ metadata: HotKeyConfig.HotKeyMetadata,
        onTrigger: @escaping () -> Void,
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil
    ) {
        HotKeyCenter.shared.unregister(metadata.id!)

        guard let firstKey = metadata.keyCode.first else {
            onSuccess?()
            return
        }

        let success = HotKeyCenter.shared.register(
            keyCode: firstKey,
            modifiers: metadata.modifiers,
            idGen: { metadata.id!.toEventHotKeyID() },
            handler: onTrigger
        )

        if success {
            onSuccess?()
        } else {
            onFailure?()
        }
    }
}
