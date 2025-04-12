import Foundation
import RealmSwift

class DBConjugate: Object {
    @objc dynamic var type: String = ""
    @objc dynamic var typeId: Int = 0
    let forms = List<DBFormRow>()
    @objc dynamic var wordId: String = ""
}

class DBExample: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var wordId: String = ""
    @objc dynamic var subdetailsId: String = ""
    @objc dynamic var relaId: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var lang: String = ""
    @objc dynamic var notationTitle: String? = nil

    override static func primaryKey() -> String? {
        return "objectId"
    }
}

class DBFormData: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var form: String = ""
    @objc dynamic var name: String = ""
}

class DBFormRow: Object {
    @objc dynamic var id: String = ""
    let forms = List<DBFormData>()
}

class DBRelatedWord: Object {
    @objc dynamic var wordId: String = ""
    let synonyms = List<DBSynonym>()
    let paronyms = List<DBSynonym>()
    let polyphonics = List<DBSynonym>()
}

class DBSubdetail: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var wordId: String = ""
    @objc dynamic var lang: String = ""
    @objc dynamic var relaId: String = ""

    override static func primaryKey() -> String? {
        return "objectId"
    }
}

class DBSynonym: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var spell: String = ""
    @objc dynamic var pron: String? = nil

    override static func primaryKey() -> String? {
        return "objectId"
    }
}

class DBWord: Object {
    @objc dynamic var objectId: String = ""
    let exampleIds = List<String>()
    @objc dynamic var isShared: Bool = false
    @objc dynamic var status: String = ""
    let subdetailsIds = List<String>()
    let details = List<DBWordDetail>()
    let subdetails = List<DBSubdetail>()
    let examples = List<DBExample>()
    @objc dynamic var relatedWord: DBRelatedWord?
    @objc dynamic var conjugate: DBConjugate?
    let type = RealmOptional<Int>()
    @objc dynamic var romajiHepburn: String? = nil
    @objc dynamic var romajiHepburnCN: String? = nil
    @objc dynamic var accent: String? = nil
    @objc dynamic var spell: String? = nil
    @objc dynamic var pron: String? = nil
    @objc dynamic var excerpt: String? = nil

    override static func primaryKey() -> String? {
        return "objectId"
    }
}

class DBWordDetail: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var wordId: String = ""
    let partOfSpeech = List<Int>()

    override static func primaryKey() -> String? {
        return "objectId"
    }
}

