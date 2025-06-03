//
//  ContentView.swift
//  SixPicks
//
//  Created by Martin Olate on 3/19/25.
//

import SwiftUI
import PhotosUI
import Photos

struct ContentView: View {
    @State private var selectedPhotos: [UIImage] = []
    @State private var isShowingDatePicker: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var isShowingExportAlert: Bool = false
    @State private var exportAlertMessage: String = ""
    
    //
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private func createCollage(from images: [UIImage]) -> UIImage? {
        let totalWidth: CGFloat = 600
        let totalHeight: CGFloat = 900
        
        guard !images.isEmpty else { return nil }
        
        let columns = 2
        let rows = 3
        let cellWidth = totalWidth / CGFloat(columns)
        let cellHeight = totalHeight / CGFloat(rows)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: totalWidth, height: totalHeight), false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        for (index, image) in images.enumerated() {
            if index >= columns * rows { break }
            
            let row = index / columns
            let col = index % columns
            let x = CGFloat(col) * cellWidth
            let y = CGFloat(row) * cellHeight
            let cellRect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
            
            if let filledImage = image.aspectFill(to: cellRect.size) {
                filledImage.draw(in: cellRect)
            }
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
   
    
    private func exportCollage() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    print("Photo library access not authorized.")
                }
                return
            }
            
            guard let collageImage = createCollage(from: selectedPhotos) else {
                DispatchQueue.main.async {
                    print("Failed to create collage.")
                }
                return
            }
            
            guard let jpegData = collageImage.jpegData(compressionQuality: 1.0) else {
                DispatchQueue.main.async {
                    print("Failed to convert collage to JPEG.")
                }
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            do {
                try jpegData.write(to: tempURL)
            } catch {
                DispatchQueue.main.async {
                    print("Error saving collage: \(error.localizedDescription)")
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tempURL)
                request?.creationDate = Date()
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Collage saved to Photos app.")
                    } else if let error = error {
                        print("Error saving collage: \(error.localizedDescription)")
                    }
                }
            })
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.blue.opacity(0.3)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Text("Find your SixPicks!")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.black)
                                .padding()
                                .multilineTextAlignment(.center)

                            Text(selectedDate, formatter: monthYearFormatter)
                                .font(.title2)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Button(action: {
                                    isShowingDatePicker = true
                                }) {
                                    Text("Select Month")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.pink)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                }

                                Button(action: {
                                    generateDump()
                                }) {
                                    Text("Generate Dump")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.teal)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                            }
                            .padding(.horizontal)

                            if !selectedPhotos.isEmpty {
                                TabView {
                                    ForEach(selectedPhotos.indices, id: \.self) { index in
                                        Image(uiImage: selectedPhotos[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity, maxHeight: 400)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                                .frame(height: 400)
                            }

                            if !selectedPhotos.isEmpty {
                                Button(action: {
                                    exportCollage()
                                }) {
                                    Text("Export")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                                .padding(.horizontal)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Home")
            .sheet(isPresented: $isShowingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate, isPresented: $isShowingDatePicker)
            }
            .alert(isPresented: $isShowingExportAlert) {
                Alert(
                    title: Text("Export"),
                    message: Text(exportAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    //function for generating photo dump
    private func generateDump() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    print("Photo library access not authorized.")
                }
                return
            }
            
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month], from: selectedDate)
            components.day = 1
            guard let monthStart = calendar.date(from: components) else { return }
            var comps = DateComponents()
            comps.month = 1
            comps.day = -1
            guard let monthEnd = calendar.date(byAdding: comps, to: monthStart) else { return }
            
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", monthStart as NSDate, monthEnd as NSDate)
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let assets = PHAsset.fetchAssets(with: .image, options: options)
            let count = assets.count
            if count == 0 {
                DispatchQueue.main.async {
                    print("No photos found for the selected month.")
                }
                return
            }
            
            let numImages = min(6, count)
            let selectedAssets: [PHAsset] = assets.objects(at: IndexSet(0..<count))
                .shuffled()
                .prefix(numImages)
                .map { $0 }
            
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false // Asynchronous request
            requestOptions.deliveryMode = .highQualityFormat
            
            var newSelectedPhotos: [UIImage] = []
            let group = DispatchGroup()
            
            for asset in selectedAssets {
                group.enter()
                imageManager.requestImage(for: asset,
                                          targetSize: CGSize(width: 300, height: 300),
                                          contentMode: .aspectFill,
                                          options: requestOptions) { image, _ in
                    if let image = image {
                        DispatchQueue.main.async {
                            newSelectedPhotos.append(image)
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.selectedPhotos = newSelectedPhotos
            }
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var selectedMonth: Int
    @State private var selectedYear: Int

    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate.wrappedValue)
        self._selectedMonth = State(initialValue: components.month ?? Calendar.current.component(.month, from: Date()))
        self._selectedYear = State(initialValue: components.year ?? Calendar.current.component(.year, from: Date()))
    }
    
    private let months = Calendar.current.monthSymbols
    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 10)...currentYear)
    }()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            // Allow selection only if month has started for current year
                            if selectedYear < Calendar.current.component(.year, from: Date()) ||
                                month <= Calendar.current.component(.month, from: Date()) {
                                Text(months[month - 1]).tag(month)
                            }
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Month")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var components = DateComponents()
                        components.year = selectedYear
                        components.month = selectedMonth
                        components.day = 1
                        if let newDate = Calendar.current.date(from: components) {
                            selectedDate = newDate
                        }
                        isPresented = false
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension UIImage {
    func aspectFill(to size: CGSize) -> UIImage? {
        let scale = max(size.width / self.size.width, size.height / self.size.height)
        let scaledWidth = self.size.width * scale
        let scaledHeight = self.size.height * scale
        let offsetX = (scaledWidth - size.width) / 2
        let offsetY = (scaledHeight - size.height) / 2
        let scaledRect = CGRect(x: -offsetX, y: -offsetY, width: scaledWidth, height: scaledHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.clip(to: CGRect(origin: .zero, size: size))
        self.draw(in: scaledRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
