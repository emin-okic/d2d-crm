//
//  ContactsContainerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI

struct ProspectContainerView: View {
    
    @Binding var selectedList: String
    @Binding var activeSearchFilter: ContactSearchFilter?
    
    @Binding var selectedProspect: Prospect?
    
    @Binding var isDeleting: Bool
    @Binding var selectedProspects: Set<Prospect>
    var onNavigateToMap: (MapContactSelection) -> Void = { _ in }
    var onProspectOpenRequested: (Prospect) -> Bool = { _ in false }

    var body: some View {
        GeometryReader { geo in
            let targetHeight = geo.size.height * 0.94

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                ProspectsSectionView(
                    selectedList: $selectedList,
                    selectedProspect: $selectedProspect,
                    containerHeight: targetHeight,
                    activeSearchFilter: $activeSearchFilter,
                    isDeleting: $isDeleting,
                    selectedProspects: $selectedProspects,
                    onNavigateToMap: onNavigateToMap,
                    onProspectOpenRequested: onProspectOpenRequested
                )
                .padding(10)
            }
            .frame(height: targetHeight, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}
