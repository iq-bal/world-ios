
//
//  CommunityPostCard.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//


import SwiftUI

struct CommunityPostCard: View {
    let post: CommunityPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.username)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(post.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(post.message)
                .font(.body)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}



