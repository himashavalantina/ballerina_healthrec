import ballerina/http;
import ballerina/io;
import ballerina/time;
import ballerina/uuid;
import ballerinax/mongodb;
import ballerina/lang.'string as strings;



// Initialize MongoDB client
final mongodb:Client mongoClient = check new ({
    connection: "mongodb+srv://himashavalantina55:Hima%401234@cluster0.ktheqad.mongodb.net/healthDB?retryWrites=true&w=majority"
});

// Define the nested map: gender -> age(months) -> GrowthRange
final map<map<GrowthRange>> weightTables = {
    "male": {
        "0": {under: 2.6, min: 3.0, max: 4.2, over: 4.4},
        "1": {under: 3.4, min: 3.9, max: 5.3, over: 5.6},
        "2": {under: 4.2, min: 4.9, max: 6.4, over: 6.9},
        "3": {under: 5.0, min: 5.7, max: 7.2, over: 7.8},
        "4": {under: 5.5, min: 6.2, max: 7.9, over: 8.5},
        "5": {under: 6.0, min: 6.7, max: 8.4, over: 9.1},
        "6": {under: 6.4, min: 7.1, max: 8.9, over: 9.6},
        "7": {under: 6.7, min: 7.4, max: 9.3, over: 10.0},
        "8": {under: 6.9, min: 7.6, max: 9.6, over: 10.4},
        "9": {under: 7.1, min: 7.9, max: 9.9, over: 10.7},
        "10": {under: 7.3, min: 8.1, max: 10.2, over: 11.0},
        "11": {under: 7.5, min: 8.3, max: 10.5, over: 11.3},
        "12": {under: 7.6, min: 8.4, max: 10.8, over: 11.5},
        "13": {under: 7.7, min: 8.6, max: 11.0, over: 11.8},
        "14": {under: 7.8, min: 8.7, max: 11.3, over: 12.1},
        "15": {under: 7.9, min: 8.9, max: 11.5, over: 12.3},
        "16": {under: 8.0, min: 9.0, max: 11.7, over: 12.5},
        "17": {under: 8.1, min: 9.2, max: 11.9, over: 12.7},
        "18": {under: 8.2, min: 9.3, max: 12.1, over: 12.9},
        "19": {under: 8.3, min: 9.4, max: 12.3, over: 13.1},
        "20": {under: 8.4, min: 9.6, max: 12.5, over: 13.3},
        "21": {under: 8.5, min: 9.7, max: 12.7, over: 13.5},
        "22": {under: 8.6, min: 9.8, max: 12.9, over: 13.7},
        "23": {under: 8.7, min: 10.0, max: 13.1, over: 13.9},
        "24": {under: 8.8, min: 10.1, max: 13.3, over: 14.1}
    },
    "female": {
        "0": {under: 2.5, min: 2.8, max: 3.9, over: 4.2},
        "1": {under: 3.2, min: 3.6, max: 4.8, over: 5.2},
        "2": {under: 3.9, min: 4.4, max: 5.9, over: 6.3},
        "3": {under: 4.5, min: 5.1, max: 6.7, over: 7.1},
        "4": {under: 5.0, min: 5.6, max: 7.3, over: 7.8},
        "5": {under: 5.4, min: 6.0, max: 7.8, over: 8.4},
        "6": {under: 5.7, min: 6.4, max: 8.2, over: 8.9},
        "7": {under: 6.0, min: 6.7, max: 8.6, over: 9.3},
        "8": {under: 6.2, min: 7.0, max: 8.9, over: 9.7},
        "9": {under: 6.4, min: 7.2, max: 9.2, over: 10.1},
        "10": {under: 6.6, min: 7.4, max: 9.5, over: 10.4},
        "11": {under: 6.8, min: 7.6, max: 9.7, over: 10.7},
        "12": {under: 6.9, min: 7.7, max: 9.9, over: 11.0},
        "13": {under: 7.0, min: 7.9, max: 10.1, over: 11.2},
        "14": {under: 7.2, min: 8.1, max: 10.3, over: 11.5},
        "15": {under: 7.3, min: 8.3, max: 10.6, over: 11.8},
        "16": {under: 7.4, min: 8.4, max: 10.8, over: 12.0},
        "17": {under: 7.5, min: 8.6, max: 11.0, over: 12.2},
        "18": {under: 7.6, min: 8.7, max: 11.2, over: 12.4},
        "19": {under: 7.7, min: 8.9, max: 11.4, over: 12.6},
        "20": {under: 7.8, min: 9.0, max: 11.6, over: 12.8},
        "21": {under: 7.9, min: 9.1, max: 11.8, over: 13.0},
        "22": {under: 8.0, min: 9.2, max: 12.0, over: 13.2},
        "23": {under: 8.1, min: 9.4, max: 12.2, over: 13.4},
        "24": {under: 8.2, min: 9.5, max: 12.4, over: 13.6}
    }
};

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

    // Signup for health records
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

     // login for health records
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

// These resource functions manage **disease history records** for each user.
// - `post addDisease`: Adds a new disease record to the `diseases` collection in MongoDB.  
  resource function post addDisease(@http:Payload DiseaseRecord disease)
    returns http:Created|http:InternalServerError|error {
        mongodb:Database db = check mongoClient->getDatabase("healthDB");
        mongodb:Collection diseaseCollection = check db->getCollection("diseases");

        _ = check diseaseCollection->insertOne(disease);
        return <http:Created>{ body: { message: "Disease record saved" } };
    }

// - `get getDiseases`: Fetches all disease records of a user (by `userId`) from MongoDB. 
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


//updates a vaccine record for a user when it is marked as received.
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



//checks a users's growth based on age, gender, weight, and height.
// It compares the provided data against WHO growth standards and returns the classification
resource function post checkGrowth(@http:Payload record {
    string userId;
    float weight;
    float height; // in cm
} payload) returns http:Ok|http:NotFound|http:BadRequest|error {

    mongodb:Database db = check mongoClient->getDatabase("healthDB");
    mongodb:Collection usersCollection = check db->getCollection("users");

    record {}? userDoc = check usersCollection->findOne({ "id": payload.userId });
    if userDoc is () {
        return <http:NotFound>{ body: { message: "User not found" } };
    }

    string gender = userDoc["gender"] is string ? <string>userDoc["gender"] : "unknown";
    gender = strings:toLowerAscii(gender);
    string dobStr = userDoc["dateOfBirth"] is string ? <string>userDoc["dateOfBirth"] : "";

    // Calculate age in months with proper error handling
    int ageInMonths = 0;
    if dobStr != "" {
        // Handle both date-only and datetime strings
        string formattedDobStr = dobStr;
        if !strings:includes(dobStr, "T") {
            formattedDobStr = dobStr + "T00:00:00";
        }
        
        time:Civil|error dobCivil = time:civilFromString(formattedDobStr);
        if dobCivil is error {
            // Try parsing as simple date using substring extraction
            if dobStr.length() >= 10 {
                string yyyy = dobStr.substring(0, 4);
                string mm = dobStr.substring(5, 7);
                string dd = dobStr.substring(8, 10);
                
                if yyyy.length() == 4 && mm.length() == 2 && dd.length() == 2 {
                    int|error year = int:fromString(yyyy);
                    int|error month = int:fromString(mm);
                    int|error day = int:fromString(dd);
                    
                    if year is int && month is int && day is int {
                        dobCivil = {
                            year: year,
                            month: month,
                            day: day,
                            hour: 0,
                            minute: 0,
                            second: 0,
                            timeAbbrev: "Z"
                        };
                    }
                }
            }
            
            if dobCivil is error {
                return <http:BadRequest>{ 
                    body: { 
                        message: "Invalid date format. Please use YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS" 
                    } 
                };
            }
        }
        
        // Now we know dobCivil is time:Civil
       time:Civil dobCivilVal = check dobCivil;

        time:Civil nowCivil = time:utcToCivil(time:utcNow());
        
        // Calculate total months difference with proper year/month conversion
        int totalMonths = (nowCivil.year - dobCivilVal.year) * 12;
        totalMonths += nowCivil.month - dobCivilVal.month;
        
        // Adjust if current day is before birth day in the month
        if nowCivil.day < dobCivilVal.day {
            totalMonths = totalMonths - 1;
        }
        
        // Ensure age can't be negative
        ageInMonths = totalMonths < 0 ? 0 : totalMonths;
    } else {
        return <http:BadRequest>{ body: { message: "Date of birth is required" } };
    }

    // For babies below 2 years (0-23 months)
    if ageInMonths < 24 {
        string classification = "Unknown";
        GrowthRange? range = ();
        
        // Get the appropriate growth table for the gender
        map<GrowthRange>? genderTable = weightTables[gender];
        if genderTable is map<GrowthRange> {
            // Get the growth range for this specific age in months
            range = genderTable[ageInMonths.toString()];
            if range is GrowthRange {
                if payload.weight < range.under {
                    classification = "Underweight";
                } else if payload.weight > range.over {
                    classification = "Overweight"; 
                } else if payload.weight >= range.min && payload.weight <= range.max {
                    classification = "Normal";
                } else {
                    classification = "Borderline";
                }
                
                return <http:Ok>{
                    body: {
                        userId: payload.userId,
                        gender: gender,
                        ageInMonths: ageInMonths,
                        weight: payload.weight,
                        height: payload.height,
                        growthRange: {
                            under: range.under,
                            min: range.min, 
                            max: range.max,
                            over: range.over
                        },
                        weightStatus: classification,
                        message: "Classification based on weight-for-age percentiles"
                    }
                };
            }
        }
        return <http:Ok>{
            body: {
                userId: payload.userId,
                gender: gender,
                ageInMonths: ageInMonths,
                weight: payload.weight,
                height: payload.height,
                message: "No growth data available for this age/gender"
            }
        };
    } else {
        // For age 2 years and above - use BMI
        float heightM = payload.height / 100.0;
        float bmi = payload.weight / (heightM * heightM);
        string bmiStatus = (bmi < 18.5) ? "Underweight" :
                         (bmi < 24.9) ? "Normal" :
                         (bmi < 29.9) ? "Overweight" : "Obese";
        
        return <http:Ok>{
            body: {
                userId: payload.userId,
                gender: gender,
                ageInMonths: ageInMonths,
                weight: payload.weight,
                height: payload.height,
                bmi: bmi,
                bmiStatus: bmiStatus,
                message: "Classification based on BMI"
            }
        };
    }
}

}