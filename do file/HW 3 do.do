********************************************************************************
** Preamble **
********************************************************************************

/*
Project: 		PADM-GP.4502.001 Homework 3
Created by: 	Monica Millay
Created on:		10/08/2023

Description:
Homework #3. Analysis of SCRIE expansion.

Notes:
Estimates from 2021 ACS. Data includes only renter households in NY.

*/


********************************************************************************
** Setup **
********************************************************************************

use "C:\Users\mlm696\OneDrive - nyu.edu\Past Semesters\Fall 2023\Using Large Data Sets in Policy Research\HW 3\HW 3 data.dta", clear
set more off 
log using "HW 3.txt", text replace

*narrow down to NYC only
recode countyfip (5 47 61 81 85 = 1) (0/4 6/46 ///
48/60 62/80 82/84 86/123 = 0), gen(county_recode)
label variable county_recode "County Recoded"
label define city 1 "NYC" 0 "Other"
label value county_recode city
tab county_recode

drop if county_recode==0
drop county_recode

********************************************************************************
** SCRIE applicants **
********************************************************************************

/*In order to be eligible for SCRIE one must meet the following conditions: 
(1)	be at least 62 years old;
(2)	live in and are on the lease of a rent-regulated apartment;
(3)	have a household income of less than $50,000; and 
(4)	be rent-burdened (i.e., spend more than 1/3 of the household income on rent)
*/

*(1) be at least 62 years old
gen senior = 1 if age > 61
replace senior = 0 if senior != 1
tab senior

/*(2) live in and are on the lease of a rent-regulated apartment
we cannot tell from ACS data if individuals live in a rent-regulated apartment.
(there is actually no dataset that keeps track of all the rent-regulated apartments in NYC)
we can try to estimate how many seniors are the tenants of record (i.e., on the lease)
by useing the "related" variable and weeding out anyone who is not the "head of household".
this isn't perfect, but it's our best estimation*/
codebook related // 101 is head of household
gen seniorhoh = 1 if senior==1 & related==101
replace seniorhoh = 0 if missing(seniorhoh)
tab seniorhoh [fw= hhwt]

*(4) be rent-burdened (i.e., spend more than 1/3 of the household income on rent)
sum rent, d
*delete observations where rent is 0
drop if rent==0 //921 observations deleted

sum hhincome, d
*delete obsrevations where income is negative
drop if hhincome < 0 //15 observations deleted

*replace income with 1 if it is 0. we need to calculate rent burden and cannot divide by 0
replace hhincome = 1 if hhincome==0
gen rent_income = (rent*12)/hhincome
gen rent_burdened = 1 if rent_income > .33
replace rent_burdened = 0 if missing(rent_burdened)
tab rent_burdened [fw=hhwt]
tab rent_burdened if seniorhoh==1 [fw=hhwt]

*there are still some high rents within this population of senior, rent-burdened households
tab rent if rent_burdened==1 & seniorhoh==1
/*this program is supposed to be for rent-regulated/affordable housing, so we'll
exclude households in the top decile for rent amount*/
ssc install winsor2
winsor2 rent, trim cuts(0 90) suffix(_tr)
sum rent_tr if rent_burdened==1 & seniorhoh==1 [fw=hhwt], d


*this will be our "potential SCRIE applicants" pool

********************************************************************************
** Analysis **
********************************************************************************
*demographics of the SCRIE population compared to heads of household in general
*see if something jumps out
sum age if rent_burdened==1 & seniorhoh==1 & rent_tr!= . [fw=hhwt], d

tab sex seniorhoh if rent_burdened==1 & rent_tr!= . [fw=hhwt], col
tab sex if related==101 [fw=hhwt]

codebook race
recode race (4/6 = 4) (8/9 = 8), gen(race2)
replace race2 = 5 if hispan !=0
label variable race2 "New race variable"
label define race2label 1 "White" 2 "Black" ///
3 "Native" 4 "Asian" 5 "Hispanic" 7 "Other" 8 "Multiracial"
label value race2 race2label
tab race2
tab race2 if rent_burdened==1 & seniorhoh==1 & rent_tr!= . [fw=hhwt]
tab race2 if related==101 [fw=hhwt]

*what is the avg and median rent of the SCRIE population
sum rent_tr if seniorhoh==1 & rent_burdened==1 [fw=hhwt], d

*what is the avg and median income of the SCRIE population
sum hhincome if seniorhoh==1 & rent_burdened==1 & rent_tr!= . [fw=hhwt], d
histogram hhincome if seniorhoh==1 & rent_burdened==1 & rent_tr!= . [fweight = hhwt], percent ytitle("Percent") xtitle("Household Income") title("Figure 1. Distribution of Potential SCRIE Applicants in NYC") note("Source: 2021 ACS via IPUMS USA")

gen income50k = 1 if hhincome <= 50000
replace income50k = 0 if missing(income50k)

log close
