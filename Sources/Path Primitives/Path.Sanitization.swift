extension Path {

    public static func sanitized(from source: Swift.String) -> Swift.String {
        var sanitized = ""
        sanitized.reserveCapacity(source.count)
        for character in source {
            if character.isLetter || character.isNumber
                || character == "_" || character == "-" || character == "."
            {
                sanitized.append(character)
            } else {
                sanitized.append("_")
            }
        }
        return sanitized
    }
}
