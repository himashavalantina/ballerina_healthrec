
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

// Incoming payload (from client)
type SignupRequest record {|
    string firstName;
    string lastName;
    string email;
    string password;
    string gender;
    string? phoneNumber;
    string dateOfBirth;              // in YYYY-MM-DD format
    VaccineRecord[]? vaccines;
|};

// Internal model we insert into DB
type User record {|
    string id;                       // system generated
    string firstName;
    string lastName;
    string email;
    string password;
    string gender;
    string? phoneNumber;
    string dateOfBirth;
    VaccineRecord[] vaccines;
|};



enum Gender {
    male = "male",
    female = "female"
}

type BMICheckRequest record {|
    string userId;
    int ageInMonths;
    string gender; // "male" or "female"
    float weight;  // in kg
    float height;  // in cm
|};

type BMICheckResponse record {|
    float height;
    string status?;
    float? bmi?;
|};

type GrowthRange record { 
    float under; 
    float min; 
    float max; 
    float over; 
};


