//
//  CharacterEditorView.swift
//  Element8
//
//  Created by Copilot on 2025-12-01 (updated).
//  Purpose: In-app editor for CharacterProfile entries.
//  Notes: This view carefully maps optional String properties into non-optional
//  Bindings for use with SwiftUI controls (TextField) to avoid Binding<String?> -> Binding<String>
//  conversion errors. It also uses safe optional checks (nil-coalescing) to avoid
//  "optional must be unwrapped" compile errors.
//
//  Behavior: Select a profile from the list to edit it. Create a new profile, edit fields,
//  and press Save to register (or overwrite) the profile in CharacterRegistry.shared.
//

import SwiftUI

struct CharacterEditorView: View {
    @State private var selectedKey: String? = nil
    @State private var draft: CharacterProfile? = nil
    @State private var showingCreateAlert: Bool = false
    @State private var newKeyName: String = ""
    @State private var saveMessage: String? = nil
    
    // Registry snapshot (we will re-read from shared registry when saving)
    private var profiles: [CharacterProfile] {
        CharacterRegistry.shared.profilesSortedByName
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left: list of profiles
                List(selection: $selectedKey) {
                    Section(header: Text("Profiles")) {
                        ForEach(profiles, id: \.key) { profile in
                            Button(action: {
                                selectedKey = profile.key
                                // Create editable draft copy
                                draft = profile
                                saveMessage = nil
                            }) {
                                HStack {
                                    if let sprite = profile.spriteName, !sprite.isEmpty {
                                        Image(sprite)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36, height: 36)
                                            .cornerRadius(4)
                                    } else {
                                        Circle()
                                            .fill(profile.color)
                                            .frame(width: 36, height: 36)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(profile.displayName)
                                        Text(profile.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(profile.key)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Section {
                        Button(action: { showingCreateAlert = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create New Profile")
                            }
                        }
                    }
                }
                .frame(minWidth: 300)
                .listStyle(SidebarListStyle())
                .alert("Create New Profile", isPresented: $showingCreateAlert) {
                    TextField("Key (unique)", text: $newKeyName)
                    Button("Create", action: createNewProfile)
                    Button("Cancel", role: .cancel) { newKeyName = "" }
                } message: {
                    Text("Enter a unique key used to reference this profile (e.g., \"ember\").")
                }
                
                Divider()
                
                // Right: editor
                if let draft = draft {
                    Form {
                        Section(header: Text("Identity")) {
                            // displayName
                            TextField("Display Name", text: Binding(
                                get: { self.draft?.displayName ?? "" },
                                set: { self.draft?.displayName = $0 }
                            ))
                            
                            // key (readonly)
                            HStack {
                                Text("Key")
                                Spacer()
                                Text(draft.key)
                                    .foregroundColor(.secondary)
                            }
                            
                            // description
                            TextField("Short description", text: Binding(
                                get: { self.draft?.description ?? "" },
                                set: { self.draft?.description = $0 }
                            ))
                        }
                        
                        Section(header: Text("Presentation")) {
                            ColorPicker("Color", selection: Binding(
                                get: { self.draft?.color ?? Color.white },
                                set: { self.draft?.color = $0 }
                            ))
                            
                            // spriteName is optional; map to non-optional Binding for TextField:
                            TextField("Sprite name (optional)", text: optionalStringBinding(
                                get: { self.draft?.spriteName },
                                set: { self.draft?.spriteName = $0 }
                            ))
                            
                            // specialAbility optional
                            TextField("Special ability (optional)", text: optionalStringBinding(
                                get: { self.draft?.specialAbility },
                                set: { self.draft?.specialAbility = $0 }
                            ))
                        }
                        
                        Section(header: Text("Stats")) {
                            HStack {
                                Text("Base Health")
                                Spacer()
                                Stepper("\(draft.baseHealth)", value: Binding(
                                    get: { self.draft?.baseHealth ?? 10 },
                                    set: { self.draft?.baseHealth = $0 }
                                ), in: 1...999)
                            }
                            
                            HStack {
                                Text("Movement")
                                Spacer()
                                Stepper("\(draft.movementModifier)", value: Binding(
                                    get: { self.draft?.movementModifier ?? 0 },
                                    set: { self.draft?.movementModifier = $0 }
                                ), in: -5...10)
                            }
                            
                            HStack {
                                Text("Attack")
                                Spacer()
                                Stepper("\(draft.attackModifier)", value: Binding(
                                    get: { self.draft?.attackModifier ?? 0 },
                                    set: { self.draft?.attackModifier = $0 }
                                ), in: -5...10)
                            }
                            
                            HStack {
                                Text("Defense")
                                Spacer()
                                Stepper("\(draft.defenseModifier)", value: Binding(
                                    get: { self.draft?.defenseModifier ?? 0 },
                                    set: { self.draft?.defenseModifier = $0 }
                                ), in: -5...10)
                            }
                            
                            HStack {
                                Text("Heal")
                                Spacer()
                                Stepper("\(draft.healModifier)", value: Binding(
                                    get: { self.draft?.healModifier ?? 0 },
                                    set: { self.draft?.healModifier = $0 }
                                ), in: -5...10)
                            }
                        }
                        
                        Section {
                            HStack {
                                Spacer()
                                Button(action: saveDraft) {
                                    Text("Save Profile")
                                }
                                .buttonStyle(.borderedProminent)
                                Spacer()
                            }
                            
                            if let msg = saveMessage {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .navigationTitle("Edit Profile")
                } else {
                    VStack(spacing: 16) {
                        Text("Select a profile to edit or create a new one.")
                            .foregroundColor(.secondary)
                        Button("Create new profile") {
                            showingCreateAlert = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Character Editor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Quick-refresh: clear selection to force re-read from registry
                        selectedKey = nil
                        draft = nil
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Clear selection")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Create a new profile with the provided newKeyName. Ensures key is non-empty and unique.
    private func createNewProfile() {
        let key = newKeyName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return }
        guard CharacterRegistry.shared.profile(forKey: key) == nil else {
            // Key exists; append unique suffix
            let uniqueKey = key + "-" + UUID().uuidString.prefix(4)
            newKeyName = uniqueKey
            return
        }
        
        let newProfile = CharacterProfile(
            key: key,
            displayName: key.capitalized,
            description: "",
            baseHealth: 10,
            color: .white,
            spriteName: nil,
            elementCase: nil,
            movementModifier: 0,
            attackModifier: 0,
            defenseModifier: 0,
            healModifier: 0,
            specialAbility: nil
        )
        CharacterRegistry.shared.register(newProfile)
        // Immediately select and present draft
        selectedKey = newProfile.key
        draft = newProfile
        newKeyName = ""
        showingCreateAlert = false
        saveMessage = "Profile '\(newProfile.displayName)' created."
    }
    
    /// Save the currently edited draft back to the registry
    private func saveDraft() {
        guard let d = draft else { return }
        // Validate: displayName non-empty
        if d.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveMessage = "Display name must not be empty."
            return
        }
        // Register/overwrite
        CharacterRegistry.shared.register(d)
        saveMessage = "Saved '\(d.displayName)'."
        
        // Refresh selection (re-read sorted list on next render)
        selectedKey = d.key
    }
    
    /// Adapter to map an Optional<String> into a Binding<String> suitable for TextField.
    /// When writing back, empty string is converted into nil.
    private func optionalStringBinding(get: @escaping () -> String?, set: @escaping (String?) -> Void) -> Binding<String> {
        Binding<String>(
            get: {
                // Return empty string for nil so TextField shows empty text
                return get() ?? ""
            },
            set: { newValue in
                // Convert empty string back to nil for the model to keep semantics
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    set(nil)
                } else {
                    set(trimmed)
                }
            }
        )
    }
}

// MARK: - Preview

struct CharacterEditorView_Previews: PreviewProvider {
    static var previews: some View {
        // Pre-register a couple of demo profiles for the preview
        let demo1 = CharacterProfile(key: "fire", displayName: "Fire", description: "Fierce attacker", baseHealth: 12, color: .red, spriteName: "char_fire", elementCase: .fire, movementModifier: 0, attackModifier: 2, defenseModifier: 0, healModifier: 0, specialAbility: "Inferno Strike")
        let demo2 = CharacterProfile(key: "water", displayName: "Water", description: "Defensive", baseHealth: 11, color: .blue, spriteName: nil, elementCase: .water, movementModifier: 0, attackModifier: 0, defenseModifier: 1, healModifier: 0, specialAbility: nil)
        CharacterRegistry.shared.register(demo1)
        CharacterRegistry.shared.register(demo2)
        
        return CharacterEditorView()
            .previewLayout(.sizeThatFits)
    }
}
