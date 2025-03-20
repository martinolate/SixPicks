//
//  PhotoSelectionView.swift
//  SixPicks
//
//  Created by Martin Olate on 3/19/25.
//

import SwiftUI
import PhotosUI

struct PhotoSelectionView: View {
    @Binding var selectedPhotos: [UIImage]
    
    @State private var isShowingPhotoPicker: Bool = false
    @State private var replacingIndex: Int? = nil
    
    // 3-column grid layout for photos
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select Your Photos")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    .multilineTextAlignment(.center)
                
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(selectedPhotos.indices, id: \.self) { index in
                            Image(uiImage: selectedPhotos[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(8)
                                .shadow(radius: 4)
                                .onTapGesture {
                                    replacingIndex = index
                                    isShowingPhotoPicker = true
                                }
                        }
                    }
                    .padding()
                }
                
                NavigationLink(destination: TemplateCustomizationView()) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Photo Selection")
            .sheet(isPresented: $isShowingPhotoPicker) {
                if let index = replacingIndex {
                    SinglePhotoPicker { image in
                        if let image = image {
                            selectedPhotos[index] = image
                        }
                        isShowingPhotoPicker = false
                    }
                }
            }
        }
    }
}

struct SinglePhotoPicker: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: SinglePhotoPicker
        
        init(_ parent: SinglePhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else {
                parent.completion(nil)
                return
            }
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.completion(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.parent.completion(nil)
                    }
                }
            }
        }
    }
}

// Placeholder view for Template Customization Screen
struct TemplateCustomizationView: View {
    var body: some View {
        Text("Template Customization Screen")
            .font(.largeTitle)
            .padding()
    }
}

struct PhotoSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoSelectionView(selectedPhotos: .constant([]))
    }
}
