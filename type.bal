import ballerina/time;


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


enum Gender {
    male = "male",
    female = "female"
}

type Login record {| 
    string email;
    string password;
|};

type DocApoinment record {| 
    time:Utc date;
    string time;
    string place;
    string disease;
|};



type BMI record {| 
    float weight;
    float height;
|};


// type CommonRecord record {| 
//     BMI bmi;
//     DocApoinment[] appointments;
//     VaccineRecord[] vaccines;
//     Disease[] diseases;
// |};

// type BelowTwo record {| 
//     BMI bmi;
//     VaccineRecord[] vaccines;
//     Disease[] diseases;
// |};

// type AboveTwo record {| 
//     BMI bmi;
//     VaccineRecord[] vaccines;
//     Disease[] diseases;
// |};
