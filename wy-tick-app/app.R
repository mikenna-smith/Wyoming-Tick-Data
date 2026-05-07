library(shiny)
library(bslib)
library(tidyverse)
library(leaflet)
library(sf)
library(DT)
library(rsconnect)




# ----------------- READ IN DATA ------------------
tick_data <- read_csv("data/tick_data.csv") %>%
  filter(!is.na(latitude), !is.na(longitude)) %>% 
  filter(!species %in% c("Amblyomma americanum", "Ixodes cookei", "Dermacentor similis")) %>% 
  filter(year >= 2023) %>% 
  filter(!county %in% c("Unknown", "Sweetwater"))


# ------------------- UI -------------------------
ui <- page_sidebar(
  title = "Wyoming Tick Surveillance Dashboard: 2023-2025",
  
  sidebar = sidebar(
    title = "Filter Tick Records",
    helpText("Explore the data by clicking or unclicking the filters listed here on the left hand side"),
    
    checkboxGroupInput(
      "species_filter",
      "Species",
      choices = sort(unique(tick_data$species)),
      selected = "Dermacentor andersoni"
    ), 
    
    checkboxGroupInput(
      "ctfv_filter",
      "CTFV Result",
      choices = sort(unique(tick_data$ctfv_result)),
      selected = sort(unique(tick_data$ctfv_result))
    ),
    
    checkboxGroupInput(
      "county_filter",
      "County",
      choices = sort(unique(tick_data$county)),
      selected = "Teton"
      
    ),
    
    checkboxGroupInput(
      "year_filter",
      "Year",
      choices = sort(unique(tick_data$year)),
      selected = 2025
    )
  ),
  
  
  p("In 2023, Teton County Weed & Pest District (TCWP) initiated the first tick surveillance program in Wyoming to address knowledge gaps about ticks and tick-borne diseases. The goal of this program is to inform public health and protect the community from tick-borne diseases, such as Colorado Tick Fever Virus (CTFV). This program is housed at TCWP but through collaboration with other entities throughout the state, including other Weed & Pest Districts, mosquito control Districts, and state partners, we have been able to collect tick data from all over the state. This dashboard represents tick data collected between 2023-2025. Ticks associated with out of state travel are not included."),
  
  # ----------------- SUMMARY VALUE BOXES ---------------
  layout_columns(
    col_widths = c(4, 4, 4),
    gap = "1rem",
    
    value_box(
      title = "Total Ticks Collected",
      value = textOutput("total_ticks")
    ),
    
    value_box(
      title = "CTFV Positive Collections",
      value = textOutput("positive_collections")
    ),
    
    value_box(
      title = "Counties Represented",
      value = textOutput("county_count")
    )
  ),
  
  
  # ---------------- MAP + BARPLOT -------------------
  layout_columns(
    col_widths = c(6, 6),
    
    card(
      card_header("Tick Collection Map"),
      leafletOutput("tick_map", height = "450px")
    ),
    
    card(
      card_header("Ticks Per Hour by Location"),
      plotOutput("ticks_per_hour_location_plot", height = "450px")
    )
  )
)

# ------------------- SERVER --------------------------
server <- function(input, output, session) {
  
  # Reactive filtered dataset
  filtered_ticks <- reactive({
    tick_data %>%
      filter(
        species %in% input$species_filter,
        ctfv_result %in% input$ctfv_filter,
        county %in% input$county_filter,
        year %in% input$year_filter
      )
  })
  
  # ----------------- SUMMARY CARDS ---------------------
  output$total_ticks <- renderText({
    sum(filtered_ticks()$total, na.rm = TRUE)
  })
  
  output$positive_collections <- renderText({
    filtered_ticks() %>%
      filter(ctfv_result == "positive") %>%
      nrow()
  })
  
  output$county_count <- renderText({
    filtered_ticks() %>%
      distinct(county) %>%
      nrow()
  })
  
  # --------------- TICK COLLECTION MAP ----------------
  output$tick_map <- renderLeaflet({
    dat <- filtered_ticks() %>%
      filter(!is.na(latitude), !is.na(longitude), !is.na(species))
    
    species_levels <- sort(unique(tick_data$species))
    
    set1_colors <- RColorBrewer::brewer.pal(9, "Set1")
    set1_colors_no_red <- set1_colors[set1_colors != "#E41A1C"]
    
    species_colors <- rep(
      set1_colors_no_red,
      length.out = length(species_levels)
    )
    
    species_pal <- colorFactor(
      palette = species_colors,
      domain = species_levels
    )
    
    leaflet(dat) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        radius = ~sqrt(total + 1),
        fillColor = ~species_pal(species),
        fillOpacity = 0.75,
        color = ~ifelse(ctfv_result == "positive", "red", species_pal(species)),
        stroke = TRUE,
        weight = ~ifelse(ctfv_result == "positive", 4, 1),
        popup = ~paste0(
          "<strong>Species:</strong> ", species, "<br>",
          "<strong>CTFV result:</strong> ", ctfv_result, "<br>",
          "<strong>County:</strong> ", county, "<br>",
          "<strong>Year:</strong> ", year, "<br>",
          "<strong>Total ticks:</strong> ", total
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = species_pal,
        values = dat$species,
        title = "Species",
        opacity = 1
      ) %>%
      addControl(
        html = "<div style='background: white; padding: 8px; border-radius: 5px;'>
                <strong>CTFV Status</strong><br>
                <span style='color: red; font-size: 18px;'>&#9679;</span> Positive
              </div>",
        position = "bottomleft"
      )
  })
  
  # ------------SUMMARY TABLE ----------
  output$ticks_per_hour_location_plot <- renderPlot({
    filtered_ticks() %>%
      filter(!is.na(gen_location), !is.na(ticks_per_hour)) %>%
      group_by(gen_location) %>%
      summarise(
        mean_ticks_per_hour = mean(ticks_per_hour, na.rm = TRUE),
        has_positive = any(ctfv_result == "positive", na.rm = TRUE),
        .groups = "drop"
      ) %>%
      ggplot(aes(
        x = reorder(gen_location, mean_ticks_per_hour),
        y = mean_ticks_per_hour,
        fill = has_positive
      )) +
      geom_col() +
      coord_flip() +
      scale_fill_manual(
        values = c("FALSE" = "black", "TRUE" = "red"),
        labels = c("FALSE" = "No CTFV detected", "TRUE" = "CTFV detected"),
        name = "CTFV Status"
      ) +
      labs(
        x = "General Location",
        y = "Average Ticks Collected per Hour on Trails"
      )+
      theme_minimal() +
      theme(
        axis.text.y = element_text(size = 11, face = "bold", color = "black"),
        axis.text.x = element_text(size = 10, color = "black"),
        axis.title = element_text(size = 12, face = "bold"),
        legend.title = element_text(size = 12, face = "bold"),
        legend.text = element_text(size = 11),
        legend.key.size = unit(0.8, "cm")
      )
  })
}

# -------- RUN APP ------------
shinyApp(ui = ui, server = server)




