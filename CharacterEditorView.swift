
// CharacterEditorView.swift
// In-app character registry editor for Element8
//
// New file (2025-12-01) — allows viewing, editing, and creating CharacterProfile entries
// stored in CharacterRegistry.shared. Edits call register(_:) to persist changes into the registry's storage.

import SwiftUI

struct CharacterEditorView: View {
    @State private var showingNewProfileSheet = false
    @State private var selectedProfile: CharacterProfile? = nil
    @State private var refreshTick: Int = 0 // force view refresh
    
    // Get a local copy for listing
    private var profiles: [CharacterProfile] {
        CharacterRegistry.shared.profilesSortedByName
    }
    
    var body: some View {
        List {
            Section {
                ForEach(profiles, id: \.self) { profile in
                    Button(action: {
                        selectedProfile = profile
                    }) {
                        HStack {
                            if let sprite = profile.spriteName, !sprite.isEmpty {
                                Image(sprite)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                    .cornerRadius(6)
                            } else {
                                Circle()
                                    .fill(profile.color)
                                    .frame(width: 44, height: 44)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(profile.displayName)
                                    .font(.headline)
                                Text(profile.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("HP: \(profile.baseHealth)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            } header: {
                Text("Characters")
            }
            
            Section {
                Button(action: {
                    showingNewProfileSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Create New Profile")
                    }
                }
            }
        }
        .sheet(item: $selectedProfile) { profile in
            ProfileEditorView(profile: profile) {
                // on save refresh list
                refreshTick += 1
            }
        }
        .sheet(isPresented: $showingNewProfileSheet) {
            NewProfileView {
                showingNewProfileSheet = false
                refreshTick += 1
            }
        }
        .navigationTitle("Edit Characters")
    }
}

// Editor used for an existing profile
struct ProfileEditorView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var editable: CharacterProfile
    var onSave: () -> Void
    
    init(profile: CharacterProfile, onSave: @escaping () -> Void) {
        _editable = State(initialValue: profile)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    Text("Key (immutable)")
                    Text(editable.key)
                        .foregroundColor(.secondary)
                    
                    TextField("Display Name", text: $editable.displayName)
                    TextField("Description", text: $editable.description)
                }
                
                Section("Stats") {
                    Stepper(value: $editable.baseHealth, in: 1...99) {
                        Text("Base Health: \(editable.baseHealth)")
                    }
                    Stepper(value: $editable.movementModifier, in: -3...5) {
                        Text("Movement Modifier: \(editable.movementModifier)")
                    }
                    Stepper(value: $editable.attackModifier, in: -3...5) {
                        Text("Attack Modifier: \(editable.attackModifier)")
                    }
                    Stepper(value: $editable.defenseModifier, in: -3...5) {
                        Text("Defense Modifier: \(editable.defenseModifier)")
                    }
                    Stepper(value: $editable.healModifier, in: -3...5) {
                        Text("Heal Modifier: \(editable.healModifier)")
                    }
                }
                
                Section("Appearance") {
                    ColorPicker("Color", selection: $editable.color)
                    TextField("Sprite Name (asset)", text: Binding($editable.spriteName, replacingNilWith: ""))
                }
                
                Section("Gameplay") {
                    TextField("Special Ability", text: Binding($editable.specialAbility, replacingNilWith: ""))
                    // Optionally allow mapping to existing ElementCharacter
                    Picker("Map to ElementCase (optional)", selection: Binding(get: {
                        editable.elementCase?.rawValue ?? "None"
                    }, set: { newValue in
                        if newValue == "None" {
                            editable.elementCase = nil
                        } else {
                            editable.elementCase = ElementCharacter.allCases.first(where: { $0.rawValue == newValue })
                        }
                    })) {
                        Text("None").tag("None")
                        ForEach(ElementCharacter.allCases.map { $0.rawValue }, id: \.self) { val in
                            Text(val).tag(val)
                        }
                    }
                }
            }
            .navigationTitle("Edit \(editable.displayName)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        CharacterRegistry.shared.register(editable)
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// New profile creation
struct NewProfileView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var key: String = ""
    @State private var displayName: String = ""
    @State private var description: String = ""
    @State private var baseHealth: Int = 10
    @State private var color: Color = .gray
    @State private var spriteName: String = ""
    @State private var movementModifier: Int = 0
    @State private var attackModifier: Int = 0
    @State private var defenseModifier: Int = 0
    @State private var healModifier: Int = 0
    @State private var specialAbility: String = ""
    @State private var mapToElement: String = "None"
    
    var onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Key (unique, e.g., 'fire')", text: $key)
                    TextField("Display Name", text: $displayName)
                    TextField("Description", text: $description)
                }
                
                Section("Stats") {
                    Stepper(value: $baseHealth, in: 1...99) {
                        Text("Base Health: \(baseHealth)")
                    }
                    Stepper(value: $movementModifier, in: -3...5) {
                        Text("Movement Modifier: \(movementModifier)")
                    }
                    Stepper(value: $attackModifier, in: -3...5) {
                        Text("Attack Modifier: \(attackModifier)")
                    }
                    Stepper(value: $defenseModifier, in: -3...5) {
                        Text("Defense Modifier: \(defenseModifier)")
                    }
                    Stepper(value: $healModifier, in: -3...5) {
                        Text("Heal Modifier: \(healModifier)")
                    }
                }
                
                Section("Appearance") {
                    ColorPicker("Color", selection: $color)
                    TextField("Sprite Name (asset)", text: $spriteName)
                }
                
                Section("Gameplay") {
                    TextField("Special Ability", text: $specialAbility)
                    Picker("Map to ElementCase (optional)", selection: $mapToElement) {
                        Text("None").tag("None")
                        ForEach(ElementCharacter.allCases.map { $0.rawValue }, id: \.self) { val in
                            Text(val).tag(val)
                        }
                    }
                }
            }
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !key.trimmingCharacters(in: .whitespaces).isEmpty, !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
                            return
                        }
                        let mapped: ElementCharacter? = ElementCharacter.allCases.first(where: { $0.rawValue == mapToElement })
                        let newProfile = CharacterProfile(
                            key: key.trimmingCharacters(in: .whitespacesAndNewlines),
                            displayName: displayName,
                            description: description,
                            baseHealth: baseHealth,
                            color: color,
                            spriteName: spriteName.isEmpty ? nil : spriteName,
                            elementCase: mapped,
                            movementModifier: movementModifier,
                            attackModifier: attackModifier,
                            defenseModifier: defenseModifier,
                            healModifier: healModifier,
                            specialAbility: specialAbility.isEmpty ? nil : specialAbility
                        )
                        CharacterRegistry.shared.register(newProfile)
                        onCreate()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Convenience binding to allow TextField with optional String
extension Binding where Value == String? {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(get: { source.wrappedValue ?? defaultValue }, set: { newVal in
            source.wrappedValue = newVal.isEmpty ? nil : newVal
        })
    }
}

struct CharacterEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CharacterEditorView()
        }
    }
}
