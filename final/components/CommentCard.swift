//
//  CommentCard.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//


import SwiftUI

struct CommentCard: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.username)
                    .font(.headline)
                Spacer()
                Text(comment.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(comment.message)
                .font(.body)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 3)
    }
}
