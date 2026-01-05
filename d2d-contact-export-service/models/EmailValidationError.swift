//
//  EmailValidationError.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//


enum EmailValidationError: String {
    case invalidFormat = "Please enter a valid email address"
    case blockedDomain = "Please use a non-disposable email domain"
}
