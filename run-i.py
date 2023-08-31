import os
import numpy as np
import glob
from astropy.io import fits
import pickle as pkl
import matplotlib.pyplot as plt
from lsst.daf.butler import Butler
import lsst.afw.display as afwDisplay
import lsst.afw.image as afwImage
from astropy.table import Table, vstack, join
from scipy import stats
from scipy.optimize import curve_fit
from lsst.obs.lsst import Latiss
camera = Latiss().getCamera()
from matplotlib.pyplot import cm
from scipy import stats
from scipy import interpolate
import matplotlib.ticker as mticker
from astropy.stats import sigma_clipped_stats
from photutils.detection import DAOStarFinder
from astropy.visualization import SqrtStretch
from photutils.aperture import CircularAperture



def display(exposure,title=None):
    afwDisplay.setDefaultBackend('matplotlib') 
    fig = plt.figure(figsize=(10,10))
    afw_display = afwDisplay.Display(1)
    afw_display.scale('asinh', 'zscale')
    afw_display.mtv(exposure.getImage())
    plt.title(title)
    plt.gca().axis('off')

def get_astropy_wcs(image):
    from astropy.wcs import WCS
    print(image.getWcs())
    
    wcs_dict = dict()
    for val in image.getWcs().getFitsMetadata():
        wcs_dict[str(val)] = image.getWcs().getFitsMetadata()[str(val)]

    return WCS(wcs_dict)

def get_astropy_wcs_from_image(image):
    from astropy.wcs import WCS
    
    wcs_dict = dict()
    for val in image.getWcs().getFitsMetadata():
        wcs_dict[str(val)] = image.getWcs().getFitsMetadata()[str(val)]

    return WCS(wcs_dict)

def get_astropy_wcs_from_image_file(image_fits):
    from astropy.wcs import WCS
    hdu = fits.open(image_fits)
    wcs = WCS(hdu['SkyWcs'].header)
    hdu.close()
    
    return wcs


def find_stars_on_sky(image):
    from astropy.stats import sigma_clipped_stats
    from photutils.datasets import load_star_image
    from photutils.detection import DAOStarFinder
    from astropy.wcs import WCS

    data = image.getImage().getArray()
    wcs = get_astropy_wcs_from_image(image)
    mean, median, std = sigma_clipped_stats(data, sigma=3.0)   

    daofind = DAOStarFinder(fwhm=3.0, threshold=5.*std)  
    sources = daofind(data - median)  

    for col in sources.colnames:  
        if col not in ('id', 'npix'):
            sources[col].info.format = '%.2f'  # for consistent table output

    sky_coords = [wcs.pixel_to_world(source['xcentroid'], source['ycentroid']).transform_to('galactic') for source in sources]
    
    sources.add_columns([[c.l for c in sky_coords], [c.b for c in sky_coords]], names=['l (deg)', 'b (deg)'])
    
    #sources.pprint(max_width=76)  
    
    return sources 


def get_2nd_mom_from_hsm_result(results):
    # Calculate Second Moments
    e1 = results.observed_shape.e1
    e2 = results.observed_shape.e2
    sigma = results.moments_sigma
    sigma_ave = sigma / (1 - e1**2 - e2**2 )**(0.25) 
    Ixx = (1+e1) * sigma_ave**2
    Iyy = (1-e1) * sigma_ave**2
    Ixy = e2 * (sigma_ave**2) 
    
    return Ixx, Iyy, Ixy


def get_star_stats(stars,image, ind, showSpot=True):
    import galsim
    
    #image = imageobj.getImage().getArray()
    
    result = np.zeros((1, 4))
    star = stars[ind]

    (x,y) = (0,0)
    if 'xcentroid' in stars.columns:
        y = star['xcentroid']
        x = star['ycentroid']
    else:
        y = star['base_SdssCentroid_x']
        x = star['base_SdssCentroid_y']

    #r = np.sqrt(star['npix']/np.pi)
    s = 40

    xmin = int(max(0,x-s))
    xmax = int(min(image.shape[0]-1, x+s+1))
    ymin = int(max(0,y-s))
    ymax = int(min(image.shape[1]-1, y+s+1))
    stamp = galsim.Image(image[xmin:xmax,ymin:ymax])

    if showSpot:
        plt.imshow(image[xmin:xmax,ymin:ymax])

    try:
        res = galsim.hsm.FindAdaptiveMom(stamp)
        ixx,iyy,ixy = get_2nd_mom_from_hsm_result(res)
        result = [np.max(image[xmin:xmax,ymin:ymax]),ixx,iyy,ixy,res.moments_sigma,res.moments_amp]
    except:
        result = [np.nan,np.nan,np.nan,np.nan,np.nan,np.nan]
        
    
    return stamp.array,result

def loader(i, size, scaled=False):
    load = "." * int(((i+1)/size)*100)
    load_ext = " " * (100 - len(load))
    
    if scaled:
        load = "." * (i+1)
        load_ext = " " * (size - i - 1)

    print("[" + load + load_ext + "] " + f"{i+1}/{size} ({round((i+1) / size * 100., 0)}%)", end='\r')

    return 

def interpolate_background(array):
    array[array==0] = np.nan
    x = np.arange(0, array.shape[1])
    y = np.arange(0, array.shape[0])
    #mask invalid values
    array = np.ma.masked_invalid(array)
    xx, yy = np.meshgrid(x, y)
    #get only the valid values
    x1 = xx[~array.mask]
    y1 = yy[~array.mask]
    newarr = array[~array.mask]

    interpolated_image = interpolate.griddata((x1, y1), newarr.ravel(), (xx, yy), method='nearest')

    return interpolated_image

def remove_background(image):
    from astropy.stats import SigmaClip
    from photutils.background import Background2D,MedianBackground, SExtractorBackground

    # First pass to get rough background estimate
    sigmaclip = SigmaClip(sigma=5.)
    bkg_estimator = MedianBackground()
    bkg = Background2D(image, (65,65), filter_size=(5, 5), 
                        sigma_clip=sigmaclip, 
                        bkg_estimator=bkg_estimator)


    # Second pass ignoring spots pixels
    diff = image - bkg.background
    from astropy.stats import sigma_clip
    coverage_mask = sigma_clip(diff, sigma=5, grow=2.0,maxiters=5, masked=True).mask
    del diff
    bkg = Background2D(image, (65, 65), filter_size=(5, 5), 
                        sigma_clip=None, 
                        bkg_estimator=bkg_estimator, 
                        coverage_mask=coverage_mask)

    # Interpolate over spot regions (coverage mask area)
    new_bkg = interpolate_background(bkg.background)

    return image - new_bkg

def remove_blended_sources(src, thresh):
    import itertools

    new_src = src.copy()
    combinations = list(itertools.combinations(range(0,len(src)-1), 2))
    #print(len(src), np.min(range(0,len(src))), np.max(range(0,len(src))))
    bad = []
    for pair in combinations:
        (i,j) = src[pair[0]], src[pair[1]]
        good = (np.sqrt((i['xcentroid'] - j['xcentroid'])**2 + (i['ycentroid'] - j['ycentroid'])**2) > thresh)
        
        if not good:
            bad.extend(pair)

    if len(bad) == 0:
        return src
        
    new_src.remove_rows(np.unique(bad))
    #print(f"{len(src)} -> {len(new_src)}")

    return new_src

def remove_edge_sources_from_catalog(catalog,npix=30):
    from lsst.obs.lsst import Latiss
    camera = Latiss().getCamera()

    new_catalog = catalog.copy()
    good_sources = np.zeros((len(new_catalog),16), dtype=bool)

    for i, amp in enumerate(camera[0].getAmplifiers()):
        xmin = amp.getBBox().erodedBy(npix).minX
        xmax = amp.getBBox().erodedBy(npix).maxX
        ymin = amp.getBBox().erodedBy(npix).minY
        ymax = amp.getBBox().erodedBy(npix).maxY

        good = (catalog['ycentroid'] > ymin) \
            * (catalog['ycentroid'] < ymax+1) \
            * (catalog['xcentroid'] > xmin) \
            * (catalog['xcentroid'] < xmax+1)

        
        good_sources[:,i] = good
    

    mask = np.any(good_sources,axis=1)

    return new_catalog[mask]

def get_excluded_edges(npix=30):
    """
    Returns a numpy.ndarray where True if near an amplifier or detector edge.
    """
    from lsst.obs.lsst import Latiss
    camera = Latiss().getCamera()

    included = np.zeros((camera[0].getBBox().height, camera[0].getBBox().width), dtype=bool)

    for i, amp in enumerate(camera[0].getAmplifiers()):

        xmin = amp.getBBox().erodedBy(npix).minX
        xmax = amp.getBBox().erodedBy(npix).maxX
        ymin = amp.getBBox().erodedBy(npix).minY
        ymax = amp.getBBox().erodedBy(npix).maxY

        included[ymin:ymax+1,xmin:xmax+1] = True

    return ~included
    
repo = "/repo/embargo"
butler = Butler(repo)
registry = butler.registry


def get_stars(refs):
    output = np.array([np.nan, np.nan, np.nan,np.nan,np.nan,np.nan])
    nstars = np.zeros(len(refs))
    for n,r in enumerate(refs):
        # Print progress
        loader(n, len(refs), scaled=False)

        # Get the image
        image = subbutler.get('postISRCCD',dataId = r.dataId, collections=['u/abrought/latiss/stars.SDSSi_65mm.2023.08.03'])

        # Remove the background
        img = remove_background(image.getImage().getArray())

        # Find the stars
        mean, median, std = sigma_clipped_stats(img, sigma=3.0)
        daofind = DAOStarFinder(fwhm=10.0, threshold=5.*std)  
        stars = daofind(img)
        
        # Find the best sources
        npix = 100
        stars = remove_blended_sources(stars, 100.)
        stars = remove_edge_sources_from_catalog(stars, npix=npix)

        # Get the statistics for each star
        res = np.full( (len(stars), 6), np.nan )
        for i in range(len(stars)):
            _, stats = get_star_stats(stars, img, i, showSpot=False)
            res[i,:] = stats
        
        output = np.vstack((output,res))
        nstars[n] = len(stars)
        
    return output, nstars


subbutler = Butler(repo,collections=['u/abrought/latiss/stars.SDSSi_65mm.2023.08.03'])
subregistry = subbutler.registry

refs = list(subregistry.queryDatasets(datasetType='postISRCCD', collections=['u/abrought/latiss/stars.SDSSi_65mm.2023.08.03'])) 

output, nstars = get_stars(refs)

print(nstars)

np.save("improved_output_i.npy", output)

#for num in nstars:
#    print(f"Found {nstars[num]} stars!") 

print("Done!")