import ballerina/http;
import ballerina/io;
import ballerina/time;
import ballerina/uuid;
import ballerinax/mongodb;
import ballerina/lang.'string as strings;

// Define VaccineRecord type
type VaccineRecord record {|
    string name;
    string dose;
    boolean received;
    string receivedDate?;
|};
type DiseaseRecord record {|
    string userId;
    string diseaseName;
    string symptoms?;
    string date;
|};

type Signup record {|
    string id;
    string firstName;
    string lastName;
    string email;
    string password;
    string gender;
    string dateOfBirth;
    VaccineRecord[] vaccines;
|};

// Initialize MongoDB client
final mongodb:Client mongoClient = check new ({
    connection: "mongodb+srv://himashavalantina55:Hima%401234@cluster0.ktheqad.mongodb.net/healthDB?retryWrites=true&w=majority"
});

// Function to get default vaccines by gender
function getDefaultVaccines(string gender) returns VaccineRecord[] {
    VaccineRecord[] vaccines = [
        // First Year of Life
        { name: "BCG (Tuberculosis)", dose: "1 dose at 0-4 weeks", received: false, receivedDate: () },
        { name: "OPV", dose: "1st dose at 2 months", received: false, receivedDate: () },
        { name: "OPV", dose: "2nd dose at 4 months", received: false, receivedDate: () },
        { name: "OPV", dose: "3rd dose at 6 months", received: false, receivedDate: () },
        { name: "OPV", dose: "4th dose at 18 months", received: false, receivedDate: () },
        { name: "OPV", dose: "5th dose at 5 years", received: false, receivedDate: () },
        { name: "Pentavalent (DTP-HepB-Hib)", dose: "1st dose at 2 months", received: false, receivedDate: () },
        { name: "Pentavalent (DTP-HepB-Hib)", dose: "2nd dose at 4 months", received: false, receivedDate: () },
        { name: "Pentavalent (DTP-HepB-Hib)", dose: "3rd dose at 6 months", received: false, receivedDate: () },
        { name: "fIPV", dose: "1st dose at 2 months", received: false, receivedDate: () },
        { name: "fIPV", dose: "2nd dose at 4 months", received: false, receivedDate: () },
        { name: "MMR", dose: "1st dose at 9 months", received: false, receivedDate: () },

        // Second Year of Life
        { name: "Live JE", dose: "1 dose at 12 months", received: false, receivedDate: () },
        { name: "DTP", dose: "4th dose at 18 months", received: false, receivedDate: () },

        // Pre-School
        { name: "MMR", dose: "2nd dose at 3 years", received: false, receivedDate: () },

        // School Age
        { name: "DT", dose: "5th dose at 5 years", received: false, receivedDate: () },
        { name: "HPV", dose: "1st dose at 10 years (Grade 6)", received: false, receivedDate: () },
        { name: "HPV", dose: "2nd dose – 6 months after 1st dose", received: false, receivedDate: () },
        { name: "aTd", dose: "6th dose at 11 years (Grade 7)", received: false, receivedDate: () }
    ];
    
    // Females of child-bearing age
    if strings:toLowerAscii(gender) == "female" {
        vaccines.push({ name: "Rubella-containing vaccine (MMR)", dose: "1 dose (15–44 years)", received: false, receivedDate: () });

        // Pregnant women – TT
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "1st dose – 1st pregnancy, after 12 weeks POA", received: false, receivedDate: () });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "2nd dose – 4–8 weeks after 1st dose", received: false, receivedDate: () });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "3rd dose – 2nd pregnancy, after 12 weeks POA", received: false, receivedDate: () });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "4th dose – 3rd pregnancy, after 12 weeks POA", received: false, receivedDate: () });
        vaccines.push({ name: "Tetanus Toxoid (TT)", dose: "5th dose – 4th pregnancy, after 12 weeks POA", received: false, receivedDate: () });
    }

    return vaccines;
}

// Health service definition
service /health on new http:Listener(9090) {


    // Signup with proper vaccine initialization
    resource function post signup(@http:Payload Signup newUser) 
            returns http:Created|http:BadRequest|http:InternalServerError|error {
        io:println("Signup request received for: ", newUser.email);
        
        mongodb:Database db = check mongoClient->getDatabase("healthDB");
        mongodb:Collection usersCollection = check db->getCollection("users");

        // Generate user metadata
        newUser.id = uuid:createType1AsString();
        newUser.dateOfBirth = time:utcNow().toString();
        newUser.vaccines = getDefaultVaccines(newUser.gender);

        // Create document with proper structure
        record {| Signup value; |} mongoDoc = { value: newUser };
        _ = check usersCollection->insertOne(mongoDoc);

        return <http:Created>{
            body: {
                message: "User created successfully",
                userId: newUser.id,
                vaccineCount: newUser.vaccines.length()
            }
        };
    }

resource function post login(@http:Payload record {string email; string password;} credentials) 
        returns http:Ok|http:Unauthorized|http:InternalServerError|error {
    io:println("Login attempt for: ", credentials.email);

    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");

    // Find user with matching credentials
    stream<record {}, error?> resultStream = check usersCollection->find({
        email: credentials.email,
        password: credentials.password
    });
    
    // Get the first matching document
    record {}|error? result = check resultStream.next();
    
    if result is record {} {
        // First access the "value" field which contains our user data
        anydata valueField = result["value"];
        
        if valueField is record {} {
            map<anydata> userMap = <map<anydata>>valueField;
            
            // Debug: Print all available fields
            io:println("User document fields: ", userMap.keys());
            
            // Extract fields with proper type checking
            string firstName = userMap["firstName"] is string ? <string>userMap["firstName"] : "";
            string lastName = userMap["lastName"] is string ? <string>userMap["lastName"] : "";
            string userId = userMap["id"] is string ? <string>userMap["id"] : 
                           (userMap["_id"] is string ? <string>userMap["_id"] : "");

            io:println("Extracted values - firstName: ", firstName, 
                      ", lastName: ", lastName, 
                      ", userId: ", userId);
            
            return <http:Ok>{
                body: {
                    message: "Login successful",
                    userId: userId,
                    name: firstName + " " + lastName,
                    email: credentials.email
                }
            };
        } else {
            io:println("'value' field is not a record");
            return <http:InternalServerError>{
                body: {message: "Invalid user data format"}
            };
        }
    } else {
        io:println("Login failed for: ", credentials.email);
        return <http:Unauthorized>{
            body: {message: "Invalid credentials"}
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
            returns http:Ok|http:NotFound|http:InternalServerError|error {
        mongodb:Database db = check mongoClient->getDatabase("healthDB");
        mongodb:Collection usersCollection = check db->getCollection("users");

        record {}? userDoc = check usersCollection->findOne({id: userId});
        
        if userDoc is record {} && userDoc["value"] is record {} {
            record {| anydata...; |} value = <record {| anydata...; |}>userDoc["value"];
            
            VaccineRecord[] vaccines = [];
            if value["vaccines"] is anydata[] {
                vaccines = from var item in <anydata[]>value["vaccines"]
                          where item is map<anydata>
                          select {
                              name: item["name"] is string ? <string>item["name"] : "",
                              dose: item["dose"] is string ? <string>item["dose"] : "",
                              received: item["received"] is boolean ? <boolean>item["received"] : false,
                              receivedDate: item["receivedDate"] is string ? <string>item["receivedDate"] : ()
                          };
            }
            return <http:Ok>{ body: vaccines };
        }
        return <http:NotFound>{ body: { message: "User not found" } };
    }

    // Mark a vaccine as received
    resource function put markVaccineReceived(@http:Payload record {
        string userId;
        string vaccineName;
        string dose;
        string receivedDate;
    } payload) returns http:Ok|http:NotFound|error {
        mongodb:Database db = check mongoClient->getDatabase("healthDB");
        mongodb:Collection usersCollection = check db->getCollection("users");

        // Find and update the specific vaccine
        mongodb:UpdateResult result = check usersCollection->updateOne(
            { 
                "id": payload.userId,
                "value.vaccines": {
                    "$elemMatch": {
                        "name": payload.vaccineName,
                        "dose": payload.dose
                    }
                }
            },
            {
                "$set": {
                    "value.vaccines.$.received": true,
                    "value.vaccines.$.receivedDate": payload.receivedDate
                }
            }
        );

        if result.modifiedCount == 0 {
            return <http:NotFound>{ 
                body: { message: "Vaccine not found or already marked as received" } 
            };
        }
        return <http:Ok>{ body: { message: "Vaccine marked as received" } };
    }

resource function post addDefaultVaccines(@http:Payload record {
    string userId;
    VaccineRecord[] selectedVaccines;
} payload) returns http:Ok|http:NotFound|http:InternalServerError|error {
    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");

    // Create filter
    map<json> filter = { "id": payload.userId };

    // First get the current document
    record {}? userDoc = check usersCollection->findOne(filter);
    
    if userDoc is record {} {
        VaccineRecord[] currentVaccines = [];
        
        // Check for vaccines array in different possible locations using member access
        // Case 1: Direct vaccines array in document
        anydata vaccinesField = userDoc["vaccines"];
        if vaccinesField is anydata[] {
            currentVaccines = from var item in <anydata[]>vaccinesField
                             where item is map<anydata>
                             select {
                                 name: item["name"] is string ? <string>item["name"] : "",
                                 dose: item["dose"] is string ? <string>item["dose"] : "",
                                 received: item["received"] is boolean ? <boolean>item["received"] : false,
                                 receivedDate: item["receivedDate"] is string ? <string>item["receivedDate"] : ()
                             };
        } 
        // Case 2: Nested in "value" field
        else {
            anydata valueField = userDoc["value"];
            if valueField is record {} {
                record {anydata vaccines?;} value = <record {anydata vaccines?;}>valueField;
                anydata nestedVaccines = value["vaccines"];
                if nestedVaccines is anydata[] {
                    currentVaccines = from var item in <anydata[]>nestedVaccines
                                     where item is map<anydata>
                                     select {
                                         name: item["name"] is string ? <string>item["name"] : "",
                                         dose: item["dose"] is string ? <string>item["dose"] : "",
                                         received: item["received"] is boolean ? <boolean>item["received"] : false,
                                         receivedDate: item["receivedDate"] is string ? <string>item["receivedDate"] : ()
                                     };
                }
            }
        }
        
        // Merge with new vaccines
        VaccineRecord[] updatedVaccines = [];
        foreach var vaccine in currentVaccines {
            updatedVaccines.push(vaccine);
        }
        foreach var vaccine in payload.selectedVaccines {
            updatedVaccines.push(vaccine);
        }
        
        // Prepare update - try both document structures
        mongodb:UpdateResult result;
        if userDoc["vaccines"] is anydata[] {
            // Update direct vaccines array
            result = check usersCollection->updateOne(filter, {
                "$set": { "vaccines": updatedVaccines }
            });
        } else if userDoc["value"] is record {} {
            // Update nested vaccines array
            result = check usersCollection->updateOne(filter, {
                "$set": { "value.vaccines": updatedVaccines }
            });
        } else {
            return <http:NotFound>{ body: { message: "Invalid user document structure" } };
        }
        
        if result.modifiedCount > 0 {
            return <http:Ok>{ 
                body: { 
                    message: "Selected vaccines added successfully",
                    count: payload.selectedVaccines.length()
                } 
            };
        } else {
            return <http:InternalServerError>{
                body: {message: "Failed to update vaccines"}
            };
        }
    } else {
        return <http:NotFound>{ body: { message: "User not found" } };
    }
}
    /// Add custom vaccine not in default list
    resource function post addCustomVaccine(@http:Payload record {
        string userId;
        VaccineRecord vaccine;
    } payload) returns http:Ok|http:NotFound|error {
        mongodb:Database db = check mongoClient->getDatabase("healthDB");
        mongodb:Collection usersCollection = check db->getCollection("users");

        // Add the new vaccine to user's array
        mongodb:UpdateResult result = check usersCollection->updateOne(
            { "id": payload.userId },
            { "$push": { "value.vaccines": payload.vaccine } }
        );

        if result.matchedCount == 0 {
            return <http:NotFound>{ body: { message: "User not found" } };
        }
        return <http:Ok>{ body: { message: "Custom vaccine added successfully" } };
    }

    // Get recommended vaccines based on gender
    resource function get getRecommendedVaccines(@http:Query string gender) 
            returns http:Ok|http:BadRequest {
        return <http:Ok>{ body: getDefaultVaccines(gender) };
    }
}
