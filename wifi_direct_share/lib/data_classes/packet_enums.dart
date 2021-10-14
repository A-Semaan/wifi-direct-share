enum PacketType {
  PACKET,
  TRANSACTION_ACCEPTED,
  TRANSACTION_HEADER,
  TRANSACTION_TRAILER,
  NEXT_FILE,
  NEXT_PACKET,
}
enum PacketStatus {
  BEGIN,
  END,
  MID,
}

extension PacketTypeExtension on PacketType {
  static PacketType fromJson(String value) {
    if (value == "PACKET") {
      return PacketType.PACKET;
    } else if (value == "TRANSACTION_ACCEPTED") {
      return PacketType.TRANSACTION_ACCEPTED;
    } else if (value == "TRANSACTION_HEADER") {
      return PacketType.TRANSACTION_HEADER;
    } else if (value == "TRANSACTION_TRAILER") {
      return PacketType.TRANSACTION_TRAILER;
    } else if (value == "NEXT_FILE") {
      return PacketType.NEXT_FILE;
    } else if (value == "NEXT_PACKET") {
      return PacketType.NEXT_PACKET;
    } else {
      throw new Exception("invalid PacketType value");
    }
  }

  String toJson() {
    if (this == PacketType.PACKET) {
      return "PACKET";
    } else if (this == PacketType.TRANSACTION_ACCEPTED) {
      return "TRANSACTION_ACCEPTED";
    } else if (this == PacketType.TRANSACTION_HEADER) {
      return "TRANSACTION_HEADER";
    } else if (this == PacketType.TRANSACTION_TRAILER) {
      return "TRANSACTION_TRAILER";
    } else if (this == PacketType.NEXT_FILE) {
      return "NEXT_FILE";
    } else if (this == PacketType.NEXT_PACKET) {
      return "NEXT_PACKET";
    } else {
      return "";
    }
  }
}

extension PacketStatusExtension on PacketStatus {
  static PacketStatus fromJson(String value) {
    if (value == "BEGIN") {
      return PacketStatus.BEGIN;
    } else if (value == "END") {
      return PacketStatus.END;
    } else if (value == "MID") {
      return PacketStatus.MID;
    } else {
      throw new Exception("invalid PacketType value");
    }
  }

  String toJson() {
    if (this == PacketStatus.BEGIN) {
      return "BEGIN";
    } else if (this == PacketStatus.END) {
      return "END";
    } else if (this == PacketStatus.MID) {
      return "MID";
    } else {
      return "";
    }
  }
}
