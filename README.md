# Wyoming's First Tick Surveillance Program

This R Shiny App allows users to explore tick collection data from Wyoming between 2023–2025. Tick research & surveillance has been historically lacking in Wyoming, but Teton County Weed & Pest District staff Entomologist Mikenna Smith initiated the state's first program in 2023. The goal of this program is to inform public health through tick and tick-borne disease surveillance. The primary pathogen of interest to survey for in the early years of the program has been Colorado Tick Fever Virus (CTFV). This Shiny App will allow the public to view the progress of the program and learn specifically which areas around Wyoming have high tick abundances, which species, and which areas have been found to have CTFV-positive ticks.

------------------------------------------------------------------------

## Overview

This app defaults to certain data filters, including Teton County for the year 2025 and the tick species *Dermacentor andersoni.* Using this shiny app, users can explore tick collections between different years, counties, or tick species. The reactive elements of the map include:

-   An interactive map where the user can visualize the location of the data they have filtered to

-   See how many ticks were collected given the filters chosen

-   See how many of those collections were CTFV positive

-   See how many counties the data are representing at any point

-   View a reactive bar chart indicating for certain tick collections, how many ticks on average can be found on a trail at the general location listed on the y-axis. The bar chart also indicates in red if CTFV was detected at that general location.

------------------------------------------------------------------------

## Data

The data used to build this interactive map are not publicly available yet. These data are from my own research and will be publicly available after publication.

------------------------------------------------------------------------

## Packages Used

This shiny app was built in R using the following packages:

-   shiny

-   leaflet

-   sf

-   dplyr

-   ggplot2

-   DT

------------------------------------------------------------------------

## Project Structure

``` text
Wyoming-Tick-Data/
├── README.md
├── Wyoming-Tick-Data.Rproj
└── wy-tick-app/
    ├── app.R
    └── data/
        └── tick_data.csv
```

------------------------------------------------------------------------

## Future Directions

Tick surveillance data continue to be collected annually. As such, future versions of this app will include:

-   Additional years of surveillance data

-   Expanded tick-borne pathogen testing data

-   More public-facing educational resources

-   Additional interactive tools to filter and visualize more data
