import ballerina/http;
import ballerina/io;
//import ballerina/time;
import ballerina/uuid;
import ballerinax/mongodb;
import ballerina/lang.'string as strings;



// Initialize MongoDB client
final mongodb:Client mongoClient = check new ({
    connection: "mongodb+srv://himashavalantina55:Hima%401234@cluster0.ktheqad.mongodb.net/healthDB?retryWrites=true&w=majority"
});

// Function to get default vaccines by gender
function getDefaultVaccines(string gender) returns VaccineRecord[] {
    VaccineRecord[] vaccines = [
        // First Year of Life
        { name: "BCG (Tuberculosis)", dose: "1 dose at 0-4 weeks", received: false },
        { name: "OPV", dose: "1st dose at 2 months", received: false },
        { name: "OPV", dose: "2nd dose at 4 months", received: false },
        { name: "OPV", dose: "3rd dose at 6 months", received: false },
        { name: "OPV", dose: "4th dose at 18 months", received: false },
        { name: "OPV", dose: "5th dose at 5 years", received: false },
        { name: "Pentavalent (DTP-HepB-Hib)", dose: "1st dose at 2 months", received: false },
        { name: "Pentavalent (DTP-HepB-Hib)", dose: "2nd dose at 4 months", received: false },
        { name: "Pentavalent (DTP-HepB-Hib)", dose: "3rd dose at 6 months", received: false },
        { name: "fIPV", dose: "1st dose at 2 months", received: false },
        { name: "fIPV", dose: "2nd dose at 4 months", received: false },
        { name: "MMR", dose: "1st dose at 9 months", received: false },

        // Second Year of Life
        { name: "Live JE", dose: "1 dose at 12 months", received: false },
        { name: "DTP", dose: "4th dose at 18 months", received: false },

        // Pre-School
        { name: "MMR", dose: "2nd dose at 3 years", received: false },

        // School Age
        { name: "DT", dose: "5th dose at 5 years", received: false },
        { name: "HPV", dose: "1st dose at 10 years (Grade 6)", received: false },
        { name: "HPV", dose: "2nd dose – 6 months after 1st dose", received: false },
        { name: "aTd", dose: "6th dose at 11 years (Grade 7)", received: false }
    ];
    
    // Females of child-bearing age
    if strings:toLowerAscii(gender) == "female" {
        vaccines.push({ name: "Rubella-containing vaccine (MMR)", dose: "1 dose (15–44 years)", received: false });

        // Pregnant women – TT
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "1st dose – 1st pregnancy, after 12 weeks POA", received: false });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "2nd dose – 4–8 weeks after 1st dose", received: false });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "3rd dose – 2nd pregnancy, after 12 weeks POA", received: false });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "4th dose – 3rd pregnancy, after 12 weeks POA", received: false });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "5th dose – 4th pregnancy, after 12 weeks POA", received: false });
    }

    return vaccines;
}

// Health service definition
service /health on new http:Listener(9090) {

    // Signup with proper vaccine initialization
resource function post signup(@http:Payload SignupRequest signupReq) 
        returns http:Created|http:BadRequest|error {

VaccineRecord[] vaccinesToStore;

if signupReq.vaccines is VaccineRecord[] {
    // Unwrap the optional array safely
    VaccineRecord[] tempVaccines = <VaccineRecord[]>signupReq.vaccines;

    if tempVaccines.length() > 0 {
        vaccinesToStore = tempVaccines;
    } else {
        vaccinesToStore = getDefaultVaccines(signupReq.gender);
    }
} else {
    vaccinesToStore = getDefaultVaccines(signupReq.gender);
}

User newUser = {
    id: uuid:createType1AsString(),
    firstName: signupReq.firstName,
    lastName: signupReq.lastName,
    email: signupReq.email,
    password: signupReq.password,
    gender: signupReq.gender,
    phoneNumber: signupReq.phoneNumber,
    dateOfBirth: signupReq.dateOfBirth,
    vaccines: vaccinesToStore
};




    // Insert into MongoDB
    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");
    _ = check usersCollection->insertOne(newUser);
    

    return <http:Created>{
        body: {
            message: "User created successfully",
            userId: newUser.id,
            vaccineCount: newUser.vaccines.length()
        }
    };
}


resource function post login(@http:Payload record {
    string email;
    string password;
} credentials) returns http:Ok|http:Unauthorized|error {
    io:println("Login attempt for: ", credentials.email);

    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");

    // Find user by email and password
    record {}? userDoc = check usersCollection->findOne({
        email: credentials.email,
        password: credentials.password
    });

    if userDoc is record {} {
        // Extract fields safely
        string userId = userDoc["id"] is string ? <string>userDoc["id"] : "";
        string firstName = userDoc["firstName"] is string ? <string>userDoc["firstName"] : "";
        string lastName = userDoc["lastName"] is string ? <string>userDoc["lastName"] : "";

        return <http:Ok>{
            body: {
                message: "Login successful",
                userId: userId,
                name: firstName + " " + lastName,
                email: credentials.email
            }
        };
    } else {
        return <http:Unauthorized>{
            body: { message: "Invalid credentials" }
        };
    }
}
resource function post addDisease(@http:Payload DiseaseRecord disease)
    returns http:Created|http:InternalServerError|error {
        mongodb:Database db = check mongoClient->getDatabase("healthDB");
        mongodb:Collection diseaseCollection = check db->getCollection("diseases");

        _ = check diseaseCollection->insertOne(disease);
        return <http:Created>{ body: { message: "Disease record saved" } };
    }

    resource function get getDiseases(@http:Query string userId)
    returns http:Ok|http:InternalServerError|error {
        mongodb:Database db = check mongoClient->getDatabase("healthDB");
        mongodb:Collection diseaseCollection = check db->getCollection("diseases");

        stream<DiseaseRecord, error?> resultStream = check diseaseCollection->find({ userId: userId });
        DiseaseRecord[] diseases = [];

        while true {
            record {|DiseaseRecord value;|}? result = check resultStream.next();
            if result is record {|DiseaseRecord value;|} {
                diseases.push(result.value);
            } else {
                break;
            }
        }

        return <http:Ok>{ body: diseases };
    }

    // Get user's vaccines (default + custom)
resource function get getVaccines(@http:Query string userId)
        returns http:Ok|http:NotFound|error {

    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");

    record {}? userDoc = check usersCollection->findOne({ "id": userId });

    if userDoc is record {} {
        // 1. Determine gender
        string gender = userDoc["gender"] is string ? <string>userDoc["gender"] : "unknown";

        // 2. Start with default vaccines
        VaccineRecord[] vaccines = getDefaultVaccines(gender);

        // 3. Merge any stored vaccines (received status or custom vaccines)
        if userDoc["vaccines"] is anydata[] {
            VaccineRecord[] storedVaccines = from var item in <anydata[]>userDoc["vaccines"]
                                             where item is map<anydata>
                                             select {
                                                 name: item["name"] is string ? <string>item["name"] : "",
                                                 dose: item["dose"] is string ? <string>item["dose"] : "",
                                                 received: item["received"] is boolean ? <boolean>item["received"] : false,
                                                 receivedDate: item["receivedDate"] is string ? <string>item["receivedDate"] : ()
                                             };

            // Merge stored vaccines into default list
            foreach var sv in storedVaccines {
                boolean exists = false;
                foreach var dv in vaccines {
                    if dv.name == sv.name && dv.dose == sv.dose {
                        // Update received info in default vaccine
                        dv.received = sv.received;
                        dv.receivedDate = sv.receivedDate;
                        exists = true;
                        break;
                    }
                }
                // If vaccine is custom, add it
                if !exists {
                    vaccines.push(sv);
                }
            }
        }

        return <http:Ok>{ body: vaccines };
    }

    return <http:NotFound>{ body: { message: "User not found" } };
}



resource function put markVaccineReceived(@http:Payload record {
    string userId;
    string vaccineName;
    string dose;
    string receivedDate;
} payload) returns http:Ok|http:NotFound|error {

    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");

    // Correctly typed filter
map<json> filter = {
    "id": payload.userId,
    "vaccines": {
        "$elemMatch": {
            "name": payload.vaccineName,
            "dose": payload.dose
        }
    }
};

// Update operation using mongodb:Update
mongodb:Update updateOp = {
    set: {
        "vaccines.$.received": true,
        "vaccines.$.receivedDate": payload.receivedDate
    }
};

// Call updateOne
mongodb:UpdateResult result = check usersCollection->updateOne(filter, updateOp);


    if result.modifiedCount == 0 {
        return <http:NotFound>{ body: { message: "Vaccine not found or already marked as received" } };
    }

    return <http:Ok>{ body: { message: "Vaccine marked as received" } };
}


    // Add custom vaccine not in default list


resource function post addCustomVaccine(@http:Payload record {
    string userId;
    VaccineRecord vaccine;
} payload) returns http:Ok|http:NotFound|error {

    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");

    // 1. Fetch the user document
    record {}? userDoc = check usersCollection->findOne({ "id": payload.userId });
    if userDoc is () {
        return <http:NotFound>{ body: { message: "User not found" } };
    }

    // 2. Get current vaccines array
    VaccineRecord[] currentVaccines = [];
    if userDoc["vaccines"] is anydata[] {
        currentVaccines = from var item in <anydata[]>userDoc["vaccines"]
                          where item is map<anydata>
                          select {
                              name: item["name"] is string ? <string>item["name"] : "",
                              dose: item["dose"] is string ? <string>item["dose"] : "",
                              received: item["received"] is boolean ? <boolean>item["received"] : false,
                              receivedDate: item["receivedDate"] is string ? <string>item["receivedDate"] : ()
                          };
    }

    // 3. Append new vaccine
    currentVaccines.push(payload.vaccine);

    // 4. Update the user document with new array
    mongodb:Update updateOp = {
        set: { "vaccines": currentVaccines }
    };

    mongodb:UpdateResult result = check usersCollection->updateOne({ "id": payload.userId }, updateOp);

    return <http:Ok>{ 
        body: { 
            message: "Custom vaccine added successfully",
            modifiedCount: result.modifiedCount
        } 
    };
}




}