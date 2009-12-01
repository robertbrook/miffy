require File.dirname(__FILE__) + '/../spec_helper'

describe ActResolver, ' when matching acts' do

  def should_extract text, expected_name, expected_year
    resolver = ActResolver.new('')
    resolver.name_and_year(text).should == [expected_name, expected_year]
  end

  def should_match_acts_at text, reference_list
    resolver = ActResolver.new(text)
    refs = []
    resolver.each_reference do |reference, start_position, end_position|
      refs << [reference, start_position, end_position]
    end
    refs.size.should == reference_list.size
    refs.should == reference_list
  end

  def should_match_acts text, reference_list
    resolver = ActResolver.new(text)
    reference_list = [reference_list] if reference_list.is_a? String
    resolver.references.size.should == reference_list.size
    resolver.references.should == reference_list
  end

  def should_not_match text
    should_match_acts(text, [])
  end

  def expect_match text
    should_match_acts(text, [text])
  end

  it 'should extract a year from "Northern Ireland (Entry to Negotiations, etc.) Act 1996"' do
    should_extract "Northern Ireland (Entry to Negotiations, etc.) Act 1996", "Northern Ireland (Entry to Negotiations, etc.) Act", "1996"
  end

  it 'should not extract a year from "Tramways Act"' do
    should_extract "Tramways Act", "Tramways Act", nil
  end

  it 'should return a start_position of 0 for text "Northern Ireland Act 1996"' do
    should_match_acts_at("Northern Ireland Act 1996", [["Northern Ireland Act 1996", 0, 25]])
  end

  it "should not match 'Rent act' " do
    should_not_match("Rent act")
  end

  it "should not match 'Part III of the Act' " do
    should_not_match('Part III of the Act')
  end

  it "should not match 'Northern Ireland Acts' " do
    should_not_match('Northern Ireland Acts')
  end

  it "should match 'Rent Act' " do
    expect_match("Rent Act")
  end

  it "should match 'Rent Act 1977' " do
    expect_match("Rent Act 1977")
  end

  it 'should match "Disused Burial Grounds Act" in "passing of the Disused Burial Grounds Act"' do
    should_match_acts("passing of the Disused Burial Grounds Act", "Disused Burial Grounds Act")
  end

  it "should not match 'This Act' " do
    should_not_match("This Act")
  end

  it "should not match 'The Act' " do
    should_not_match("The Act")
  end

  it "should not match 'An Act' " do
    should_not_match("An Act")
  end

  it "should not match 'The Acts' " do
    should_not_match("The Acts")
  end

  it "should not match 'Rent Acts' " do
    should_not_match("Rent Acts")
  end

  it "should match 'Anti-Terrorism, Crime and Security Act 2001' " do
    expect_match("Anti-Terrorism, Crime and Security Act 2001")
  end

  it "should match 'Rent (Scotland) Act' " do
    expect_match("Rent (Scotland) Act")
  end

  it 'should match "&#x2014; REPRESENTATION OF THE PEOPLE ACT&2014;"  as "REPRESENTATION OF THE PEOPLE ACT"' do
    should_match_acts("&#x2014; REPRESENTATION OF THE PEOPLE ACT&2014;", "REPRESENTATION OF THE PEOPLE ACT")
  end

  it 'should match "Mental Health Act 1983"  as "Part VII of the Mental Health Act 1983"' do
    should_match_acts("Part VII of the Mental Health Act 1983", "Mental Health Act 1983")
  end

  it "should match 'Rent (Scotland) Act, 1977' " do
    expect_match("Rent (Scotland) Act, 1977")
  end

  it 'should not match "English Act"' do
    should_not_match('English Act')
  end

  it 'should match "Extradition Act"  as "Since the Extradition Act"' do
    should_match_acts("Since the Extradition Act", "Extradition Act")
  end

  it 'should match "THE ELECTRIC LIGHTING ACT&#x2014; LEGISLATION."  as "ELECTRIC LIGHTING ACT"' do
    should_match_acts("THE ELECTRIC LIGHTING ACT&#x2014; LEGISLATION.", "ELECTRIC LIGHTING ACT")
  end

  it "should match 'Mines and Quarries Act' " do
    expect_match("Mines and Quarries Act")
  end

  it "should match 'Asylum and Immigration (Treatment of Claimants, etc.) Act 2004' " do
    expect_match('Asylum and Immigration (Treatment of Claimants, etc.) Act 2004')
  end

  it "should match 'Ministerial Salaries and Members' Pensions Act' " do
    expect_match("Ministerial Salaries and Members' Pensions Act")
  end

  it "should match 'Mental Health (Patients in the Community) Act 1995' " do
    expect_match("Mental Health (Patients in the Community) Act 1995")
  end

  it "should match 'Police Act, 1964' " do
    expect_match("Police Act, 1964")
  end

  it "should not match 'Notes for the Guidance of Independent Inspectors Holding Inquiries Into Orders and Special Road Schemes Made Under the Highways Act 1980' " do
   original = 'Notes for the Guidance of Independent Inspectors Holding Inquiries Into Orders and Special Road Schemes Made Under the Highways Act 1980'
    should_not_match(original)
  end

  it 'should not match "Under the Act" ' do
    should_not_match('Under the Act')
  end

  it 'should match "Fraserburgh Harbour (No. 2) Order Confirmation Act 1985" ' do
    expect_match('Fraserburgh Harbour (No. 2) Order Confirmation Act 1985')
  end

  it 'should match "Road Traffic (Driving Instruction by Disabled Persons) Act 1993" ' do
    expect_match('Road Traffic (Driving Instruction by Disabled Persons) Act 1993')
  end

  it 'should match "Northern Ireland (Entry to Negotiations, etc.) Act 1996" ' do
    expect_match('Northern Ireland (Entry to Negotiations, etc.) Act 1996')
  end

  it 'should match "Under the Tramways Act"  as "Tramways Act"' do
    should_match_acts("Under the Tramways Act", "Tramways Act")
  end

  it 'should match "Merchant Shipping Act 1894" in "compensation under the 1886 Act and the Merchant Shipping Act 1894 to those"' do
    should_match_acts("compensation under the 1886 Act and the Merchant Shipping Act 1894 to those", "Merchant Shipping Act 1894")
  end

  it 'should match "Northern Ireland (Entry into Negotiations, etc.) Act 1996" ' do
    expect_match('Northern Ireland (Entry into Negotiations, etc.) Act 1996')
  end

  it 'should match "Ministerial and other Salaries Act 1975" ' do
    expect_match('Ministerial and other Salaries Act 1975')
  end

  it 'should match "Queen\'s Road Brighton Burial Ground Act 1975"' do
    expect_match("Queen's Road Brighton Burial Ground Act 1975")
  end

  it 'should match "Lloyd\'s Act 1982" in "Act of Parliament, the Lloyd\'s Act 1982"' do
    should_match_acts("Act of Parliament, the Lloyd's Act 1982", "Lloyd's Act 1982")
  end

  it 'should match "Provisional Collection of Taxes Act 1968" in "the Act, the Provisional Collection of Taxes Act 1968"' do
    should_match_acts("the Act, the Provisional Collection of Taxes Act 1968", "Provisional Collection of Taxes Act 1968")
  end

  it 'should match "Customs (Import Deposits) Act, 1968" in "1. Customs (Import Deposits) Act, 1968."' do
    should_match_acts("1. Customs (Import Deposits) Act, 1968.", "Customs (Import Deposits) Act, 1968")
  end

  it 'should match "European Parliament (Representation) Act 2003" in "<q>European Parliament (Representation) Act 2003</q>"' do
    should_match_acts("<q>European Parliament (Representation) Act 2003</q>", "European Parliament (Representation) Act 2003")
  end

  it 'should match "Health Protection Agency Act 2004" in "<li>Health Protection Agency Act 2004</li>"' do
    should_match_acts("<li>Health Protection Agency Act 2004</li>", "Health Protection Agency Act 2004")
  end

  it 'should match "Anguilla Act 1980" in "<p>   Anguilla Act 1980."' do
    should_match_acts("<p>   Anguilla Act 1980.", "Anguilla Act 1980")
  end

  it 'should match "Social Security Act 1975" in ">Yes, the Social Security Act 1975"' do
    should_match_acts(">Yes, the Social Security Act 1975", "Social Security Act 1975")
  end

  it 'should match "Finance Act 2000" in ">The Finance Act 2000"' do
    should_match_acts(">The Finance Act 2000", "Finance Act 2000")
  end

  it 'should match "Mental Health Act" in "right hon. Friend the Secretary of State by the Mental Health Act Commission"' do
    should_match_acts("right hon. Friend the Secretary of State by the Mental Health Act Commission", "Mental Health Act")
  end

  it 'should match "Computer Misuse Act 1990" in "Sections of the Computer Misuse Act 1990"' do
    should_match_acts("Sections of the Computer Misuse Act 1990", "Computer Misuse Act 1990")
  end

  it 'should match "Finance Act 1964" in "Schedule to the Finance Act 1964"' do
    should_match_acts("Schedule to the Finance Act 1964", "Finance Act 1964")
  end

  it 'should match "Representation of the People Act, 1884" in "The Representation of the People Act, 1884?"' do
    should_match_acts("The Representation of the People Act, 1884?", "Representation of the People Act, 1884")
  end

  it 'should match "European Communities Act 1972" in "the United Kingdom to the European Community and the European Communities Act 1972"' do
    should_match_acts("the United Kingdom to the European Community and the European Communities Act 1972", "European Communities Act 1972")
  end

  it 'should match "National Assistance Act 1948" in "Second Schedule to the National Assistance Act 1948"' do
    should_match_acts("Second Schedule to the National Assistance Act 1948", "National Assistance Act 1948")
  end

  it 'should match "British Standard Time Act" in "Second Reading of the British Standard Time Act"' do
    should_match_acts("Second Reading of the British Standard Time Act", "British Standard Time Act")
  end

  it 'should match "Race Relations Act" in "Third Reading of the Race Relations Act"' do
    should_match_acts("Third Reading of the Race Relations Act", "Race Relations Act")
  end

  it 'should match "the Housing (Homeless Persons) Act 1977" in "the Government, the Housing (Homeless Persons) Act 1977."' do
    should_match_acts("the Government, the Housing (Homeless Persons) Act 1977.", "Housing (Homeless Persons) Act 1977")
  end

  it 'should match "Mental Health Act 1983" in ""Mental Health Act 1983"' do
    should_match_acts('"Mental Health Act 1983', "Mental Health Act 1983")
  end

  it 'should match "Television Act" in "Charter and the Television Act"' do
    should_match_acts('Charter and the Television Act', 'Television Act')
  end

  it 'should match "Vehicle Excise Act" in "Authorisation of Special Types (General) Order, the Authorisation of Special Types, Special Order, the Vehicle Excise Act"' do
    should_match_acts('Authorisation of Special Types (General) Order, the Authorisation of Special Types, Special Order, the Vehicle Excise Act', 'Vehicle Excise Act')
  end

  it 'should match "Finance Act" in "Fourth Schedule to the Finance Act"' do
    should_match_acts('Fourth Schedule to the Finance Act', 'Finance Act')
  end

  it 'should match "Mines and Quarries Act" in "through the House, and the Mines and Quarries Act"' do
    should_match_acts('through the House, and the Mines and Quarries Act', 'Mines and Quarries Act')
  end

  it 'should not match "New Clause (Duration of Act,)—(Mr. H. J. Wilson,)—"' do
    should_match_acts('New Clause (Duration of Act,)—(Mr. H. J. Wilson,)—', [])
  end

  it 'should  match "Medicines Act " in "If the Medicines Act"' do
    should_match_acts('If the Medicines Act ', 'Medicines Act')
  end

  it 'should match "Fair Trading Act" in "Conservative Party for the Fair Trading Act"' do
    should_match_acts("Conservative Party for the Fair Trading Act", "Fair Trading Act")
  end

  it 'should match "Fair Trading Act" in "Labour Party for the Fair Trading Act"' do
    should_match_acts("Labour Party for the Fair Trading Act", "Fair Trading Act")
  end

  it 'should match "Fair Trading Act" in "Liberal Democrat Party for the Fair Trading Act"' do
    should_match_acts("Liberal Democrat Party for the Fair Trading Act", "Fair Trading Act")
  end

  it 'should match "Counter-Inflation Act" in "The Counter-Inflation Act"' do
    should_match_acts("The Counter-Inflation Act", "Counter-Inflation Act")
  end

  it 'should match "Pharmacy Act" and "Poisons Act" in " the amendment of the Pharmacy Act (Ireland) and the Poisons Act "' do
    should_match_acts(" the amendment of the Pharmacy Act (Ireland) and the Poisons Act ", ["Pharmacy Act", "Poisons Act"])
  end

  it 'should match "Allowances Act" in "In Part II of the Allowances Act"' do
    should_match_acts("In Part II of the Allowances Act", "Allowances Act")
  end

  it 'should match "Income Tax Act" in "the Section of the Income Tax Act"' do
    should_match_acts("the Section of the Income Tax Act", "Income Tax Act")
  end

  it 'should match "Airports Act 1986" in "House in the Airports Act 1986"' do
    should_match_acts("House in the Airports Act 1986", "Airports Act 1986")
  end

  it 'should not match "A Companies Act"' do
    should_not_match("A Companies Act")
  end

  it 'should  match "Contract of Employment Act 1972" in "A Guide to Changes in the Contract of Employment Act 1972"' do
    should_match_acts("A Guide to Changes in the Contract of Employment Act 1972", "Contract of Employment Act 1972")
  end

  it 'should match "Disability Discrimination Act" in "A Brief Guide to the Disability Discrimination Act"' do
    should_match_acts("A Brief Guide to the Disability Discrimination Act", "Disability Discrimination Act")
  end

  it 'should match "Fire Precautions Act 1971" in "A Review of the Fire Precautions Act 1971"' do
    should_match_acts("A Review of the Fire Precautions Act 1971", "Fire Precautions Act 1971")
  end

  it 'should not match "A Time to Act"' do
    should_not_match("A Time to Act")
  end

  it 'should match "Misuse of Drugs Act 1971" in "Guide to the Misuse of Drugs Act 1971"' do
    should_match_acts("Guide to the Misuse of Drugs Act 1971", "Misuse of Drugs Act 1971")
  end

  it 'should match "Abortion Act" in "According to the Abortion Act"' do
    should_match_acts("According to the Abortion Act", "Abortion Act")
  end

  it 'should not match "Addition to Naval Discipline Act 1957"' do
    should_not_match("Addition to Naval Discipline Act 1957")
  end

  it 'should match "Criminal Damage Act 1971" in "Adjusted for the Criminal Damage Act 1971"' do
    should_match_acts("Adjusted for the Criminal Damage Act 1971", "Criminal Damage Act 1971")
  end

  it 'should not match "Administration of Act"' do
    should_not_match("Administration of Act")
  end

  it 'should match "Cruelty to Animals Act 1876" in "Administration of the Cruelty to Animals Act 1876"' do
    should_match_acts("Administration of the Cruelty to Animals Act 1876", "Cruelty to Animals Act 1876")
  end

  it 'should not match "Admiralty by Act"' do
    should_not_match("Administration of Act")
  end

  it 'should match "Civil Aviation Act, 1968" in "Aerodromes (Civil Aviation Act, 1968, Section 8)"' do
    should_match_acts("Aerodromes (Civil Aviation Act, 1968, Section 8)", "Civil Aviation Act, 1968")
  end

  it 'should match "Criminal Law Act 1977" in "Arrested Persons (Criminal Law Act 1977"' do
    should_match_acts("Arrested Persons (Criminal Law Act 1977", "Criminal Law Act 1977")
  end

  it 'should match "Fair Trading Act 1973" in "Again, in the Fair Trading Act 1973"' do
    should_match_acts("Again, in the Fair Trading Act 1973", "Fair Trading Act 1973")
  end

  it 'should not match "AGREEMENTS UNDER ACT"' do
    should_not_match("AGREEMENTS UNDER ACT")
  end

  it 'should match "Commonwealth Immigrants Act 1962" in "Aliens Order in the Schedule to the Commonwealth Immigrants Act 1962"' do
    should_match_acts("Aliens Order in the Schedule to the Commonwealth Immigrants Act 1962", "Commonwealth Immigrants Act 1962")
  end

  it 'should match "Housing Act 1996" in "Allocation of Accommodation and Homelessness (Parts VI and VII ofthe Housing Act 1996)"' do
      should_match_acts("Allocation of Accommodation and Homelessness (Parts VI and VII ofthe Housing Act 1996)", "Housing Act 1996")
  end

  it 'should match "National Insurance Act" in "Amending Bill to the National Insurance Act"' do
    should_match_acts("Amending Bill to the National Insurance Act", "National Insurance Act")
  end

  it 'should match "Agricultural Holdings Act" in "Amendment in the Agricultural Holdings Act"' do
    should_match_acts("Amendment in the Agricultural Holdings Act", "Agricultural Holdings Act")
  end

  it 'should match "Criminal Justice Administration Act 1914" in "Amendment of Criminal Justice Administration Act 1914"' do
    should_match_acts("Amendment of Criminal Justice Administration Act 1914", "Criminal Justice Administration Act 1914")
  end

  it 'should not match "An, Act"' do
    should_not_match("An, Act")
  end

  it 'should not match "And Act"' do
    should_not_match("And Act")
  end

  it 'should match "Telecommunications Act" in "Amendment to the Telecommunications Act"' do
    should_match_acts("Amendment to the Telecommunications Act", "Telecommunications Act")
  end

  it 'should match "Army Act" in "Amendments of Army Act"' do
    should_match_acts("Amendments of Army Act", "Army Act")
  end

  it 'should match "Opencast Coal Act 1958" in "Amendments of the Opencast Coal Act 1958"' do
      should_match_acts("Amendments of the Opencast Coal Act 1958", "Opencast Coal Act 1958")
  end

  it 'should match "Post Office Act 1953" in "Amendments to the Post Office Act 1953"' do
    should_match_acts("Amendments to the Post Office Act 1953", "Post Office Act 1953")
  end

  it 'should match "Children Act 1989" in "An Introduction to the Children Act 1989"' do
    should_match_acts("An Introduction to the Children Act 1989", "Children Act 1989")
  end

  it 'should match "Acquisition of Land Act 1981" in "An Acquisition of Land Act 1981"' do
    should_not_match("An Acquisition of Land Act 1981")
  end

  it 'should not match "Any Companies Act"' do
    should_not_match("Any Companies Act")
  end

  it 'should not match "APPLICATION OF PROVISIONS OF LEGAL AID ACT"' do
    should_not_match("APPLICATION OF PROVISIONS OF LEGAL AID ACT")
  end

  it 'should not match "Army Acts"' do
    should_not_match("Army Acts")
  end

  it 'should match "Armed Services Act" in "Army Acts and in the Armed Services Act"' do
    should_match_acts("Army Acts and in the Armed Services Act", "Armed Services Act")
  end

  it 'should match "Land Tenure Act" in "As for the Land Tenure Act"' do
      should_match_acts("As for the Land Tenure Act", "Land Tenure Act")
  end

  it 'should not match "As to Local Government Act 1933"' do
    should_not_match("As to Local Government Act 1933")
  end

  it 'should match "INNER URBAN AREAS ACT" in "ASSISTANCE PROVIDED UNDER THE INNER URBAN AREAS ACT"' do
    should_match_acts("ASSISTANCE PROVIDED UNDER THE INNER URBAN AREAS ACT", "INNER URBAN AREAS ACT")
  end

  it 'should match "Naval Discipline Act" in "Army and Air Force Acts and of the Naval Discipline Act"' do
    should_match_acts("Army and Air Force Acts and of the Naval Discipline Act", "Naval Discipline Act")
  end

  it 'should match "Because of the Children and Young Persons Act 1969" in "Children and Young Persons Act 1969"' do
    should_match_acts("Because of the Children and Young Persons Act 1969", 'Children and Young Persons Act 1969')
  end

  it 'should not match "Before ACT"' do
    should_not_match("Before ACT")
  end

  it 'should not match "Before Lord Hardwicke\'s Marriage Act 1753"' do
    should_not_match("Before Lord Hardwicke's Marriage Act 1753")
  end

  it 'should not match "BENEFITS UNDER INDUSTRIAL INJURIES ACT"' do
    should_not_match("BENEFITS UNDER INDUSTRIAL INJURIES ACT")
  end

  it 'should match "CHILD BENEFIT ACT 1975" in "BENEFITS UNDER THE CHILD BENEFIT ACT 1975"' do
    should_match_acts('BENEFITS UNDER THE CHILD BENEFIT ACT 1975', 'CHILD BENEFIT ACT 1975')
  end

  it 'should match "Local Government Act 1939" in "Bill for the Local Government Act 1939"' do
    should_match_acts('Bill for the Local Government Act 1939', 'Local Government Act 1939')
  end

  it 'should match "Public Health Act 1936" in "Bill and of the Public Health Act 1936"' do
    should_match_acts('Bill and of the Public Health Act 1936', 'Public Health Act 1936')
  end

  it 'should match "Bill of Sale Act 1878" in "Bill of Sale Act 1878"' do
    should_match_acts('Bill of Sale Act 1878', 'Bill of Sale Act 1878')
  end

  it 'should not match "Breaches of Factory Act"' do
    should_not_match('Breaches of Factory Act')
  end

  it 'should not match "British Act"' do
    should_not_match('British Act')
  end

  it 'should match "Government of India Act 1919" in "British Parliament in the Preamble to the Government of India Act 1919"' do
    should_match_acts("British Parliament in the Preamble to the Government of India Act 1919", "Government of India Act 1919")
  end

  it 'should match "British Overseas Territories Act 2002" in "British Overseas Territories Act 2002"' do
    should_match_acts("British Overseas Territories Act 2002", "British Overseas Territories Act 2002")
  end

  it 'should not match "Budget, ACT"' do
    should_not_match('Budget, ACT')
  end

  it 'should not match "Canada\'s Act"' do
    should_not_match("Canada's Act")
  end

  it 'should match "Customs Act" in "Canada, in the Customs Act"' do
    should_match_acts("Canada, in the Customs Act", "Customs Act")
  end

  it 'should match "Child Support Act 1991" in "CSA and in the Child Support Act 1991"' do
    should_match_acts("CSA and in the Child Support Act 1991", "Child Support Act 1991")
  end

  it 'should match "PLR Act 1979" in "Commencement of the PLR Act 1979"' do
    should_match_acts("Commencement of the PLR Act 1979", "PLR Act 1979")
  end

  it 'should match "Telecommunications Act 1984" in "Certainly, in Part VI of the Telecommunications Act 1984"' do
    should_match_acts("Certainly, in Part VI of the Telecommunications Act 1984", "Telecommunications Act 1984")
  end

  it 'should match "Insolvency Act 1985" in "Copies of the Insolvency Act 1985"' do
    should_match_acts("Copies of the Insolvency Act 1985", "Insolvency Act 1985")
  end

  it 'should match "Housing Act 1988" in "Chapter I of Part I of the Housing Act 1988"' do
    should_match_acts("Chapter I of Part I of the Housing Act 1988", "Housing Act 1988")
  end

  it 'should match "Police and Criminal Evidence Act 1984" in "Changes to the Police and Criminal Evidence Act 1984"' do
    should_match_acts("Changes to the Police and Criminal Evidence Act 1984", "Police and Criminal Evidence Act 1984")
  end

  it 'should match "Constitution Act 1973" in "Chair, for the Constitution Act 1973"' do
    should_match_acts("Chair, for the Constitution Act 1973", "Constitution Act 1973")
  end

  it 'should match "Constitution Act 1973" in "Chair, for the Constitution Act 1973"' do
    should_match_acts("COMPLAINTS UNDER THE CHILDREN ACT 1989", "CHILDREN ACT 1989")
  end

  it 'should not match "Companies Acts and Insolvency Act"' do
    should_not_match("Companies Acts and Insolvency Act")
  end

  it 'should match "Criminal Justice Act 1982" in "Committees of the Criminal Justice Act 1982"' do
    should_match_acts("Committees of the Criminal Justice Act 1982", "Criminal Justice Act 1982")
  end

  it 'should match "Human Rights Act" in "DDA, the Human Rights Act"' do
    should_match_acts("DDA, the Human Rights Act", "Human Rights Act")
  end

  it 'should not match "Declaration and Final Act"' do
    should_not_match("Declaration and Final Act")
  end

  it 'should not match "Declaration to the Final Act"' do
    should_not_match("Declaration to the Final Act")
  end

  it 'should not match "Department\'s Act"' do
    should_not_match("Department's Act")
  end

  it 'should match "ENVIRONMENT ACT 1995" in "DIRECTIONS UNDER THE ENVIRONMENT ACT 1995"' do
    should_match_acts("DIRECTIONS UNDER THE ENVIRONMENT ACT 1995", "ENVIRONMENT ACT 1995")
  end

  it 'should not match "Double-Act"' do
    should_not_match("Double-Act")
  end

  it 'should not match "DIVISION OF ACT"' do
    should_not_match("DIVISION OF ACT")
  end

  it 'should match "Air Force Act 1955" in "Draft Air Force Act 1955"' do
    should_match_acts('Draft Air Force Act 1955', 'Air Force Act 1955')
  end

  it 'should match "European Communities Act 1971" in "Division List for the European Communities Act 1971"' do
    should_match_acts('Division List for the European Communities Act 1971', 'European Communities Act 1971')
  end

  it 'should not match "Earlier Act"' do
    should_not_match("Earlier Act")
  end

  it 'should not match "ENFORCEMENT NOTICES IN RESPECT OF DIRECTIONS UNDER PART II OF AVIATION SECURITY ACT 1982"' do
    should_not_match('ENFORCEMENT NOTICES IN RESPECT OF DIRECTIONS UNDER PART II OF AVIATION SECURITY ACT 1982')
  end

  it 'should not match "ENFORCEMENT OF LITTER ACT 1958"' do
    should_not_match('ENFORCEMENT OF LITTER ACT 1958')
  end

  it 'should not match "English Act"' do
    should_not_match('English Act')
  end

  it 'should not match "Every National Assistance Act"' do
    should_not_match('Every National Assistance Act')
  end

  it 'should match "Rehabilitation of Offenders Act 1974" in "Exceptions Order to the Rehabilitation of Offenders Act 1974"' do
    should_match_acts('Exceptions Order to the Rehabilitation of Offenders Act 1974', 'Rehabilitation of Offenders Act 1974')
  end

  it 'should match "Rehabilitation of Offenders Act 1974" in "Exceptions to the Rehabilitation of Offenders Act 1974"' do
    should_match_acts('Exceptions to the Rehabilitation of Offenders Act 1974', 'Rehabilitation of Offenders Act 1974')
  end

  it 'should not match "Exclusion of National Audit Act 1983"' do
    should_not_match('Exclusion of National Audit Act 1983')
  end

  it 'should match "Education Reform Act" in "Experience of the Education Reform Act"' do
    should_match_acts('Experience of the Education Reform Act', 'Education Reform Act')
  end

  it 'should match "Scotland Act 1998" in "Explanatory Memorandum to the Draft Scotland Act 1998"' do
    should_match_acts('Explanatory Memorandum to the Draft Scotland Act 1998', 'Scotland Act 1998')
  end

  it 'should match "Education (Schools) Act 1992" in "Extension of the Education (Schools) Act 1992"' do
    should_match_acts('Extension of the Education (Schools) Act 1992', 'Education (Schools) Act 1992')
  end

  it 'should not match "Extension of Fire Brigade Pensions Act 1925"' do
    should_not_match('Extension of Fire Brigade Pensions Act 1925')
  end

  it 'should match "Offices, Shops and Railway Premises Act" in "Factories Acts and Offices, Shops and Railway Premises Act"' do
    should_match_acts('Factories Acts and in the Offices, Shops and Railway Premises Act', 'Offices, Shops and Railway Premises Act')
  end

  it 'should match "Offices, Shops and Railway Premises Act" in "Factories Acts and Offices, Shops and Railway Premises Act"' do
    should_match_acts('Factories Acts and in the Offices, Shops and Railway Premises Act', 'Offices, Shops and Railway Premises Act')
  end

  it 'should not match "their Rating (Interim Relief) Act"' do
    should_not_match("their Rating (Interim Relief) Act")
  end

  it 'should match "Town and Country Planning Act 1971" in "General Development Order of the Town and Country Planning Act 1971"' do
    should_match_acts("General Development Order of the Town and Country Planning Act 1971", "Town and Country Planning Act 1971")
  end

  it 'should not match "Government\'s Clean Air Act"' do
    should_not_match("Government's Clean Air Act")
  end

  it 'should match "London Government Act" in "GLC, to the London Government Act"' do
    should_match_acts("GLC, to the London Government Act", "London Government Act")
  end

  it 'should match "House of the Data Protection Act" in "House of the Data Protection Act"' do
    should_match_acts("House of the Data Protection Act", "Data Protection Act")
  end

  it 'should match "Landlord and Tenant Act 1954" in "House to the Landlord and Tenant Act 1954"' do
    should_match_acts("House to the Landlord and Tenant Act 1954", "Landlord and Tenant Act 1954")
  end

  it 'should match "Working Classes Act 1903" in "Houses of the Working Classes Act 1903"' do
    should_match_acts("Houses of the Working Classes Act 1903", "Working Classes Act 1903")
  end

  it 'should match "However, Part II of the Development of Tourism Act 1969" in "However, Part II of the Development of Tourism Act 1969"' do
    should_match_acts("However, Part II of the Development of Tourism Act 1969", "Development of Tourism Act 1969")
  end

  it 'should match "Merchant Shipping Act 1988" in "II of the Merchant Shipping Act 1988"' do
    should_match_acts("II of the Merchant Shipping Act 1988", "Merchant Shipping Act 1988")
  end

  it 'should match "Security and Intelligence Act" in "In Australia the Security and Intelligence Act"' do
    should_match_acts("In Australia the Security and Intelligence Act", "Security and Intelligence Act")
  end

  it 'should not match "LAND TO WHICH ACT"' do
    should_not_match("LAND TO WHICH ACT")
  end

  it 'should match "Inner Urban Areas Act" in "Member for Stepney and Poplar in the Inner Urban Areas Act"' do
    should_match_acts("Member for Stepney and Poplar in the Inner Urban Areas Act", "Inner Urban Areas Act")
  end

  it 'should match "Electricity Act" in "Minister to the Electricity Act"' do
    should_match_acts("Minister to the Electricity Act", "Electricity Act")
  end

  it 'should match "AGRICULTURE ACT 1993" in "MODIFICATION OF THE AGRICULTURE ACT 1993"' do
    should_match_acts("MODIFICATION OF THE AGRICULTURE ACT 1993", "AGRICULTURE ACT 1993")
  end

  it 'should match "Army Act" in "Modifications of the Army Act"' do
    should_match_acts("Modifications of the Army Act", "Army Act")
  end

  it 'should match "Army Act 1955" in "Moved, That the Draft Army Act 1955"' do
    should_match_acts("Moved, That the Draft Army Act 1955", "Army Act 1955")
  end

  it 'should not match "My Housing (Homeless Persons) Act" ' do
    should_not_match("My Housing (Homeless Persons) Act")
  end

  it 'should not match "No Act" ' do
    should_not_match("No Act")
  end

  it 'should not match "No Official Secrets Act" ' do
    should_not_match("No Official Secrets Act")
  end

  it 'should match "RENT ACT" in "OF OFFENCES AGAINST THE RENT ACT 1965" ' do
    should_match_acts("OF OFFENCES AGAINST THE RENT ACT 1965", "RENT ACT 1965")
  end

  it 'should match "Children Act" in "On Second Reading of the Children Act"' do
    should_match_acts("On Second Reading of the Children Act", "Children Act")
  end

  it 'should match "Ecclesiastical Titles Act" in "Order for the Second Reading of the Bill for the Repeal of the Ecclesiastical Titles Act"' do
    should_match_acts("Order for the Second Reading of the Bill for the Repeal of the Ecclesiastical Titles Act", "Ecclesiastical Titles Act")
  end

  it 'should match "Municipal Corporations Act" in "Order of the Municipal Corporations Act"' do
    should_match_acts("Order of the Municipal Corporations Act", "Municipal Corporations Act")
  end

  it 'should match "Bankruptcy Act" in "Order and Disposition Clauses of the Bankruptcy Act"' do
    should_match_acts("Order and Disposition Clauses of the Bankruptcy Act", "Bankruptcy Act")
  end

  it 'should match "Finance Act" in "Order to the Finance Act"' do
    should_match_acts("Order to the Finance Act", "Finance Act")
  end

  it 'should not match "Other Highways Act" ' do
    should_not_match("Other Highways Act")
  end

  it 'should not match "Our Companies Act" ' do
    should_not_match("Our Companies Act")
  end

  it 'should match "Rent Restrictions Act" in "Owing to the Rent Restrictions Act"' do
    should_match_acts("Owing to the Rent Restrictions Act", "Rent Restrictions Act")
  end

  it 'should not match "PART II OF INDUSTRY ACT 1972" ' do
    should_not_match("PART II OF INDUSTRY ACT 1972")
  end

  it 'should match "Social Security and Housing Benefits Act 1982" in "Parts I and III of the Social Security and Housing Benefits Act 1982"' do
    should_match_acts("Parts I and III of the Social Security and Housing Benefits Act 1982", "Social Security and Housing Benefits Act 1982")
  end

  it 'should match "Control of Pollution Act 1974" in "Parts of the Control of Pollution Act 1974"' do
    should_match_acts("Parts of the Control of Pollution Act 1974", "Control of Pollution Act 1974")
  end

  it 'should match "SUSPENSION OF THE HABEAS CORPUS ACT" in "PETITION FROM BATH RESPECTING THE SUSPENSION OF THE HABEAS CORPUS ACT"' do
    should_match_acts("PETITION FROM BATH RESPECTING THE SUSPENSION OF THE HABEAS CORPUS ACT", "SUSPENSION OF THE HABEAS CORPUS ACT")
  end

  it 'should not match "PETITION OF BENJAMIN WHITELEY COMPLAINING OF THE OPERATION OF THE HABEAS CORPUS SUSPENSION ACT" ' do
    should_not_match("PETITION OF BENJAMIN WHITELEY COMPLAINING OF THE OPERATION OF THE HABEAS CORPUS SUSPENSION ACT")
  end

  it 'should match "Petition of Right Act 1627" in "Petition of Right Act 1627"' do
    should_match_acts("Petition of Right Act 1627", "Petition of Right Act 1627")
  end

  it 'should match "TEST ACT" in "PETITIONS FOR THE REPEAL OF THE TEST ACT"' do
    should_match_acts("PETITIONS FOR THE REPEAL OF THE TEST ACT", "TEST ACT")
  end

  it 'should match "Financial Services Act 1986" in "Possible Changes to the Financial Services Act 1986"' do
    should_match_acts("Possible Changes to the Financial Services Act 1986", "Financial Services Act 1986")
  end

  it 'should not match "Pre-Act" ' do
    should_not_match("Pre-Act ")
  end

  it 'should not match "Post-Act" ' do
    should_not_match("Post-Act")
  end

  it 'should not match "Prior Act" ' do
    should_not_match("Prior Act")
  end

  it 'should not match "Pro-Act" ' do
    should_not_match("Pro-Act")
  end

  it 'should match "Criminal Justice Act 1988" in "Prior to the Criminal Justice Act 1988"' do
    should_match_acts("Prior to the Criminal Justice Act 1988", "Criminal Justice Act 1988")
  end

  it 'should not match "PROVISIONS AS TO LANDLORD AND TENANT ACT 1927" ' do
    should_not_match("PROVISIONS AS TO LANDLORD AND TENANT ACT 1927")
  end

  it 'should not match "PROVISIONS INSERTED IN ROAD TRAFFIC ACT 1988" ' do
    should_not_match("PROVISIONS INSERTED IN ROAD TRAFFIC ACT 1988")
  end

  it 'should not match "Provisions Repealed in Principal Act" ' do
    should_not_match("Provisions Repealed in Principal Act")
  end

  it 'should not match "PROVISIONS TO BE SUBSTI TUTED IN FIRST SCHEDULE TO NATIONAL HEALTH SERVICE CONTRI BUTIONS ACT 1957" ' do
    should_not_match("PROVISIONS TO BE SUBSTI TUTED IN FIRST SCHEDULE TO NATIONAL HEALTH SERVICE CONTRI BUTIONS ACT 1957")
  end

  it 'should match "Education Act 1962" in "Provisions Substituted in the Education Act 1962"' do
    should_match_acts("Provisions Substituted in the Education Act 1962", "Education Act 1962")
  end

  it 'should match "Immigration Act 1971" in "Provisons of the Immigration Act 1971"' do
    should_match_acts("Provisons of the Immigration Act 1971", "Immigration Act 1971")
  end

  it 'should match "Data Protection Act" in "Provision of the Data Protection Act"' do
    should_match_acts("Provision of the Data Protection Act", "Data Protection Act")
  end

  it 'should not match "Pursuant to Private Legislation Procedure (Scotland) Act 1899" ' do
    should_not_match("Pursuant to Private Legislation Procedure (Scotland) Act 1899")
  end

  it 'should match "Small Landholders (Scotland) Act 1911" in "Purposes of the Small Landholders (Scotland) Act 1911"' do
    should_match_acts("Purposes of the Small Landholders (Scotland) Act 1911", "Small Landholders (Scotland) Act 1911")
  end

  it 'should match "Caravan Sites Act" in "Referring to the Caravan Sites Act"' do
    should_match_acts("Referring to the Caravan Sites Act", "Caravan Sites Act")
  end

  it 'should match "Factories Act" in "Regulations of the Factories Act"' do
    should_match_acts("Regulations of the Factories Act", "Factories Act")
  end

  it 'should match "Criminal Law Amendment Act 1871" in "Repeal of Criminal Law Amendment Act 1871"' do
    should_not_match("Repeal of Criminal Law Amendment Act 1871")
  end

  it 'should match "Sale of Beer Act" in "Report of the Sale of Beer Act"' do
    should_match_acts("Report of the Sale of Beer Act", "Sale of Beer Act")
  end

  it 'should match "Finance Act 1965" in "Report Stage of the Finance Act 1965"' do
    should_match_acts("Report Stage of the Finance Act 1965", "Finance Act 1965")
  end

  it 'should match "Housing Defects Act" in "Review of the Housing Defects Act"' do
    should_match_acts("Review of the Housing Defects Act", "Housing Defects Act")
  end

  it 'should match "Factories Act" in "Revision of the Factories Act"' do
    should_match_acts("Revision of the Factories Act", "Factories Act")
  end

  it 'should match "National Health Service Act" in "Second and Third Reading of the National Health Service Act"' do
    should_match_acts("Second and Third Reading of the National Health Service Act", "National Health Service Act")
  end

  it 'should not match "Second Act" ' do
    should_not_match("Second Act")
  end

  it 'should match "Local Government Act 1985" in "Secretary of State for the Environment in the Local Government Act 1985"' do
    should_match_acts("Secretary of State for the Environment in the Local Government Act 1985", "Local Government Act 1985")
  end

  it 'should match "London Regional Transport Act 1984" in "Secretary of State in the London Regional Transport Act 1984"' do
    should_match_acts("Secretary of State in the London Regional Transport Act 1984", "London Regional Transport Act 1984")
  end

  it 'should not match "See Race Relations Act 1976" ' do
    should_not_match("See Race Relations Act 1976")
  end

  it 'should not match "Second Finance Act" ' do
    should_not_match("Second Finance Act")
  end

  it 'should match "Land Utilisation Act" in "Statute Book in the Land Utilisation Act"' do
    should_match_acts("Statute Book in the Land Utilisation Act", "Land Utilisation Act")
  end

  it 'should match "Eight Hours Act" in "Statute Book of the Eight Hours Act"' do
    should_match_acts("Statute Book of the Eight Hours Act", "Eight Hours Act")
  end

  it 'should match "Statute Book the Children and Young Persons Act" in "Children and Young Persons Act"' do
    should_match_acts("Statute Book the Children and Young Persons Act", "Children and Young Persons Act")
  end

  it 'should match "Government of India Act" in "Table of Seats in Part II of the First Schedule of the Government of India Act"' do
    should_match_acts("Table of Seats in Part II of the First Schedule of the Government of India Act", "Government of India Act")
  end

  it 'should not match "That Part VIII (Personal Reliefs) of the Income Tax Act 1952"' do
    should_not_match("That Part VIII (Personal Reliefs) of the Income Tax Act 1952")
  end

  it 'should match "Finance Act" in "Third Beading of the Finance Act"' do
    should_match_acts("Third Beading of the Finance Act", "Finance Act")
  end

  it 'should match "National Health Service Act" in "Third and Fifth Schedules to the National Health Service Act"' do
    should_match_acts("Third and Fifth Schedules to the National Health Service Act", "National Health Service Act")
  end

  it 'should match "Finance Act" in "Third Beading of the Finance Act"' do
    should_match_acts("Third Beading of the Finance Act", "Finance Act")
  end

  it 'should match "Third Generation Wireless Telegraphy Act" in "Third Generation Wireless Telegraphy Act"' do
    should_match_acts("Third Generation Wireless Telegraphy Act", "Third Generation Wireless Telegraphy Act")
  end

  it 'should match "Third Parties (Rights Against Insurers) Act 1930" in "Third Parties (Rights Against Insurers) Act 1930"' do
    should_match_acts("Third Parties (Rights Against Insurers) Act 1930", "Third Parties (Rights Against Insurers) Act 1930")
  end

  it 'should match "Financial Services Act" in "Thirdly, Part IV of the Financial Services Act"' do
    should_match_acts("Thirdly, Part IV of the Financial Services Act", "Financial Services Act")
  end

  it 'should not match "This Child Care Act 1980" ' do
    should_not_match("This Child Care Act 1980")
  end

  it 'should match "Trade Disputes Act" in "Title of the Trade Disputes Act"' do
    should_match_acts("Title of the Trade Disputes Act", "Trade Disputes Act")
  end

  it 'should match "Health Service Commissioners Act 1993" in "To Amend the Health Service Commissioners Act 1993"' do
    should_match_acts("To Amend the Health Service Commissioners Act 1993", "Health Service Commissioners Act 1993")
  end

  it 'should match "Criminal Law and Procedure (Ireland) Act 1887" in "To Repeal the Criminal Law and Procedure (Ireland) Act 1887"' do
    should_match_acts("To Repeal the Criminal Law and Procedure (Ireland) Act 1887", "Criminal Law and Procedure (Ireland) Act 1887")
  end

  it 'should match "Elementary Education Act" in "Twenty-fifth Clause of the Elementary Education Act"' do
    should_match_acts("Twenty-fifth Clause of the Elementary Education Act", "Elementary Education Act")
  end

  it 'should match "Children Act 1989" in "United Kingdom the Children Act 1989"' do
    should_match_acts("United Kingdom the Children Act 1989", "Children Act 1989")
  end

  it 'should match "Children Act 1908" in "United Kingdom to the Children Act 1908"' do
    should_match_acts("United Kingdom to the Children Act 1908", "Children Act 1908")
  end

  it 'should match "Buy America Act" in "United States of America the Buy America Act"' do
    should_match_acts("United States of America the Buy America Act", "Buy America Act")
  end

  it 'should match "Taft-Hartley Act" in "United States the Taft-Hartley Act"' do
    should_match_acts("United States the Taft-Hartley Act", "Taft-Hartley Act")
  end

  it 'should match "Community Reinvestment Act" in "United States of the Community Reinvestment Act"' do
    should_match_acts("United States of the Community Reinvestment Act", "Community Reinvestment Act")
  end

  it 'should match "Taxes Act 1988" in "V of Part VII of the Taxes Act 1988"' do
    should_match_acts("V of Part VII of the Taxes Act 1988", "Taxes Act 1988")
  end

  it 'should match "Violating Act" in "Violating Act"' do
    should_match_acts("Violating Act", "Violating Act")
  end

  it 'should match "Appropriation Act" in "Vote to the Appropriation Act"' do
    should_match_acts("Vote to the Appropriation Act", "Appropriation Act")
  end

  it 'should not match "Your Act" ' do
    should_not_match("Your Act")
  end

  it 'should not match  "Acquisition of Freehold) Act"' do
    should_not_match("Acquisition of Freehold) Act")
  end

  it 'should match "Railways Act 2005 (c. 14)"' do
    expect_match('Railways Act 2005 (c. 14)')
  end

  it 'should not match "the Finance Act of that year" ' do
    should_not_match("the Finance Act of that year")
  end

  it 'should match "Video <ParaLineStart LineNum="11"></ParaLineStart>Recordings Act 1984;"' do
    expect_match('Video <ParaLineStart LineNum="11"></ParaLineStart>Recordings Act 1984')
  end

  it 'should match "Video <ParaLineStart LineNum="11"/>Recordings Act 1984;"' do
    expect_match('Video <ParaLineStart LineNum="11"/>Recordings Act 1984')
  end

  it 'should match "Section 3 of the Communications Act 2003"' do
    expect_match('Section 3 of the Communications Act 2003')
  end

  it 'should match "section <Xref id="1137592" Idref="mf.451j-1112728">124A</Xref> of the Communications Act 2003"' do
    expect_match('section <Xref id="1137592" Idref="mf.451j-1112728">124A</Xref> of the Communications Act 2003')
  end
end

describe ActResolver, " when asked for Act mention attributes" do

  before do
    @resolver = ActResolver.new("")
    @resolver.stub!(:each_reference).and_yield("An Act", 0, 5)
  end

  it 'should get the title and year of each reference from the resolver' do
    @resolver.should_receive(:name_and_year).and_return(['', nil])
    @resolver.mention_attributes
  end

  it 'should return an object with title, year, start position and end position for each reference' do
    @resolver.stub!(:name_and_year).and_return(["An Act", 1974])
    mention = @resolver.mention_attributes.first
    mention.name.should == "An Act"
    mention.text.should == "An Act"
    mention.year.should == 1974
    mention.start_position.should == 0
    mention.end_position.should == 5
    mention.section_number.should == nil
  end

  it 'should return name with markup removed' do
    resolver = ActResolver.new('section <Xref id="1137592" Idref="mf.451j-1112728">124A</Xref> of the Communications Act 2003')
    mention = resolver.mention_attributes.first
    mention.name.should == 'Communications Act'
    mention.text.should == 'section <Xref id="1137592" Idref="mf.451j-1112728">124A</Xref> of the Communications Act 2003'
    mention.year.should == '2003'
  end

  it 'should return an object with section number for section reference' do
    resolver = ActResolver.new('Section 3 of the Communications Act 2003')
    mention = resolver.mention_attributes.first
    mention.name.should == 'Communications Act'
    mention.text.should == 'Section 3 of the Communications Act 2003'
    mention.section_number.should == '3'
  end

  it 'should return an object with alphanumeric section number for section reference' do
    resolver = ActResolver.new('section 124A  of the Communications Act 2003')
    mention = resolver.mention_attributes.first
    mention.name.should == 'Communications Act'
    mention.text.should == 'section 124A  of the Communications Act 2003'
    mention.section_number.should == '124A'
  end

end
