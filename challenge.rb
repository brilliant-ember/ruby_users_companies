
require "json"

class Challenge
    # @param [String] usersJsonPath
    # @param [String] companiesJsonPath
    def initialize(usersJsonPath, companiesJsonPath)
        # good practice to init all class variables
        # in the constructor for readbility
        @companies = []
        @users = []
        @output = {}
        # init function calls
        readJsonFiles(usersJsonPath, companiesJsonPath)
    end
    def printCompanies
        puts @companies
    end
    def printUsers
        puts @users
    end

    def run
        puts "Started Program..."
        begin
        output = algorithm
        File.open("./output.txt", "w") do |f|
            f.write("\n")
            output.each do |o|
                s = formatOutputString o
                f.write(s)
            end
        end
        rescue IOError => e
            puts "IO, failed at creating ./output.txt"
        ensure
            puts "Program Exiting"
        end
    end
    def algorithm
        output = []
        users = @users.group_by{|u| u["active_status"]}
        users = users[true] # only take active users
        users = users.sort_by{ |u| u["company_id"]}
        users = users.group_by{ |u| u["company_id"]}
        companies = @companies.group_by{ |c| c["id"]}
        users.keys.each do |cId|
            info  = {}
            company = companies[cId][0]
            info [:company_id] = company["id"]
            info [:company_name] = company["name"]
            info[:users_emailed] = [] 
            info[:users_not_emailed] = []
            info[:total_topups] = 0
            companyUsers = users[cId].sort{ |a, b| a["last_name"] <=> b["last_name"] }
            companyUsers.each do |u|
                updatedUser = {}
                updatedUser[:previous_token_balance] = u["tokens"]
                updatedUser[:new_token_balance] = u["tokens"]+ company["top_up"]
                updatedUser[:first_name] = u["first_name"]
                updatedUser[:last_name] = u["last_name"]
                updatedUser[:email] = u["email"]
                info[:total_topups]+= company["top_up"]
                if company["email_status"] && u["email_status"]
                    info[:users_emailed].append updatedUser
                else
                info[:users_not_emailed].append updatedUser
                end
            end
            output.append(info)
        end
        output
    end

    private

    # @param [String] usersJsonPath
    # @param [String] companiesJsonPath
    def readJsonFiles(usersJsonPath, companiesJsonPath)
        f = File.open companiesJsonPath
        @companies = JSON.load f
        f.close
        f = File.open usersJsonPath 
        @users = JSON.load f
        f.close
    end
    # @param [Hash] u
    # @return [String]
    def formatUserInformationBlock(u)
        s = "\t\t#{u[:last_name]}, #{u[:first_name]}, #{u[:email]}\n"
        s+= "\t\t  Previous Token Balance, #{u[:previous_token_balance]}\n"
        s+= "\t\t  New Token Balance, #{u[:new_token_balance]}"
        s
    end

    # @param [Hash] o
    # @return [String]
    def formatOutputString(o)
        uEmailed = "Users Emailed:"
        o[:users_emailed].each do |u|
            uEmailed+="\n"
            uEmailed+= formatUserInformationBlock(u)
        end
        uNotEmailed = "Users Not Emailed:"
        o[:users_not_emailed].each do |u|
            uNotEmailed+="\n"
            uNotEmailed+= formatUserInformationBlock(u)
        end
        out = <<Doc
\tCompany Id: #{o[:company_id]}
\tCompany Name: #{o[:company_name]}
\t#{uEmailed}
\t#{uNotEmailed}
\t\tTotal amount of top ups for #{o[:company_name]}: #{o[:total_topups]}

Doc
    out
    end
end

c = Challenge.new("./users.json", "./companies.json")
c.run